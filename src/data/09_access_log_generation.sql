-- Access log generation (~10,000 rows)
-- Rules respected:
--   * accesses make sense according to current permissions (ip_permission / account_permission)
--   * the owner has the most accesses (~55%, plus fallback when no external access is permitted)
--   * permitted accounts (e.g. friends) get read/write, permitted IPs get operations by their flags
--   * public group files receive anonymous read-only IP traffic, private/archive files only owner traffic
--   * a log row contains either account or IP, rarely both (~8-10%, authenticated sessions)
--   * timestamps fall into the same 4-day window as the performance logs, never before the file existed

DO $$
DECLARE
    v_target int := 10000;
    v_rows int := 0;
    v_inserted int;
    v_file RECORD;
    v_perm RECORD;
    v_ts timestamp;
    v_account uuid;
    v_ip inet;
    v_op logs.operation_type;
    v_ops text[];
    v_roll float;
BEGIN
    TRUNCATE TABLE logs.access_log_row;

    WHILE v_rows < v_target LOOP
        -- Pick a random file
        SELECT f.id, f.owner_account_id, f.created_at
        INTO v_file
        FROM service.file f
        ORDER BY random()
        LIMIT 1;

        -- Timestamp within the last 4 days, but never before the file existed
        v_ts := GREATEST(
            v_file.created_at + INTERVAL '1 minute',
            CURRENT_TIMESTAMP - INTERVAL '4 days' + random() * INTERVAL '4 days'
        );

        v_account := NULL;
        v_ip := NULL;
        v_roll := random();

        IF v_roll < 0.55 THEN
            -- Owner: most accesses, all operations (read-heavy), rarely with logged IP
            v_account := v_file.owner_account_id;
            v_op := (ARRAY['read','read','read','read','read','read','write','write','create','delete']
                     ::logs.operation_type[])[1 + floor(random()*10)::int];
            IF random() < 0.08 THEN
                v_ip := ((1 + floor(random()*223))::int || '.' ||
                         floor(random()*256)::int || '.' ||
                         floor(random()*256)::int || '.' ||
                         (1 + floor(random()*254))::int)::inet;
            END IF;
        ELSE
            -- External actor: look up a permitted account for this file
            SELECT ap.account_id, ap.read_permission, ap.write_permission,
                   ap.create_permission, ap.delete_permission
            INTO v_perm
            FROM service.file_to_group ftg
            JOIN service.account_permission ap ON ap.group_id = ftg.group_id
            WHERE ftg.file_id = v_file.id
            ORDER BY random()
            LIMIT 1;

            IF v_roll < 0.80 AND v_perm.account_id IS NOT NULL THEN
                -- Permitted account (e.g. friends: read + write)
                v_account := v_perm.account_id;
                v_ops := ARRAY[]::text[];
                IF v_perm.read_permission  THEN v_ops := array_append(array_append(array_append(v_ops, 'read'), 'read'), 'read'); END IF;
                IF v_perm.write_permission THEN v_ops := array_append(array_append(v_ops, 'write'), 'write'); END IF;
                IF v_perm.create_permission THEN v_ops := array_append(v_ops, 'create'); END IF;
                IF v_perm.delete_permission THEN v_ops := array_append(v_ops, 'delete'); END IF;
                v_op := (CASE WHEN array_length(v_ops, 1) IS NULL THEN ARRAY['read']
                              ELSE v_ops END::logs.operation_type[])[1 + floor(random() *
                                  COALESCE(array_length(v_ops, 1), 1))::int];

                -- Rarely both account and IP (authenticated session)
                IF random() < 0.10 THEN
                    v_ip := ((1 + floor(random()*223))::int || '.' ||
                             floor(random()*256)::int || '.' ||
                             floor(random()*256)::int || '.' ||
                             (1 + floor(random()*254))::int)::inet;
                END IF;
            ELSE
                -- IP-based access: pick a permitted cidr for this file
                SELECT ipp.ip_mask, ipp.read_permission, ipp.write_permission,
                       ipp.create_permission, ipp.delete_permission
                INTO v_perm
                FROM service.file_to_group ftg
                JOIN service.ip_permission ipp ON ipp.group_id = ftg.group_id
                WHERE ftg.file_id = v_file.id
                ORDER BY random()
                LIMIT 1;

                IF v_perm.ip_mask IS NULL THEN
                    -- No external permission at all (private/archive files): owner reads it
                    v_account := v_file.owner_account_id;
                    v_op := 'read';
                ELSE
                    -- Derive a plausible client address inside the permitted network
                    -- /32 (family) -> exact address, /30 (work) -> one of the 4 hosts,
                    -- 0.0.0.0/0 (public) -> arbitrary public IP
                    v_ip := CASE
                        WHEN masklen(v_perm.ip_mask) >= 32 THEN host(v_perm.ip_mask)::inet
                        WHEN masklen(v_perm.ip_mask) >= 30 THEN
                            (split_part(host(network(v_perm.ip_mask)), '.', 1) || '.' ||
                             split_part(host(network(v_perm.ip_mask)), '.', 2) || '.' ||
                             split_part(host(network(v_perm.ip_mask)), '.', 3) || '.' ||
                             (split_part(host(network(v_perm.ip_mask)), '.', 4)::int
                              + floor(random()*4)::int))::inet
                        ELSE ((1 + floor(random()*223))::int || '.' ||
                              floor(random()*256)::int || '.' ||
                              floor(random()*256)::int || '.' ||
                              (1 + floor(random()*254))::int)::inet
                    END;

                    v_ops := ARRAY[]::text[];
                    IF v_perm.read_permission = 'Grant'  THEN v_ops := array_append(array_append(array_append(v_ops, 'read'), 'read'), 'read'); END IF;
                    IF v_perm.write_permission = 'Grant' THEN v_ops := array_append(array_append(v_ops, 'write'), 'write'); END IF;
                    IF v_perm.create_permission = 'Grant' THEN v_ops := array_append(v_ops, 'create'); END IF;
                    IF v_perm.delete_permission = 'Grant' THEN v_ops := array_append(v_ops, 'delete'); END IF;
                    v_op := (CASE WHEN array_length(v_ops, 1) IS NULL THEN ARRAY['read']
                                  ELSE v_ops END::logs.operation_type[])[1 + floor(random() *
                                      COALESCE(array_length(v_ops, 1), 1))::int];
                END IF;
            END IF;
        END IF;

        INSERT INTO logs.access_log_row (timestamp, account_id, ip_address, file_id, operation_type)
        VALUES (v_ts, v_account, v_ip, v_file.id, v_op)
        ON CONFLICT DO NOTHING;

        GET DIAGNOSTICS v_inserted = ROW_COUNT;
        v_rows := v_rows + v_inserted;
    END LOOP;

    RAISE NOTICE 'Generated % access log rows', v_rows;
END $$;