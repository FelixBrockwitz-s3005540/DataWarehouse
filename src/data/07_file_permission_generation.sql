-- Per group type permissions: family, work, friends, public, archive, private
-- All IPs are public-facing (the server sees client public IPs)
-- family   -> residential IP range (Grant all)
-- work     -> corporate IP collection (Grant all)
-- friends  -> a few accounts (read + edit)
-- public   -> all IPs (read only)
-- archive  -> no permission objects attached
-- private  -> explicit deny for all IPs

DO $$
DECLARE
    rec RECORD;
    v_type VARCHAR(20);
    v_hash int;
    v_residential_ip varchar(18);
    v_corporate_ip varchar(18);
BEGIN
    -- Clear previous permission objects
    TRUNCATE TABLE service.ip_permission CASCADE;
    TRUNCATE TABLE service.account_permission CASCADE;

    FOR rec IN SELECT id, name, owner_account_id FROM service.file_group
    LOOP
        -- Extract type from group name (format: user_name_type)
        v_type := split_part(rec.name, '_', array_length(string_to_array(rec.name, '_'), 1));

        IF v_type = 'archive' THEN
            CONTINUE;

        ELSIF v_type = 'family' THEN
            -- Residential IP derived from owner hash (unique per owner, /32)
            v_hash := abs(hashtext(rec.owner_account_id::text));
            v_residential_ip := (v_hash % 223 + 1)::int || '.' ||
                                ((v_hash / 256) % 256)::int || '.' ||
                                ((v_hash / 65536) % 256)::int || '.' ||
                                ((v_hash / 16777216) % 256)::int || '/32';
            INSERT INTO service.ip_permission (read_permission, write_permission, create_permission, delete_permission, priority, ip_mask, group_id)
            VALUES ('Grant', 'Grant', 'Grant', 'Grant', 1, v_residential_ip::cidr, rec.id);

        ELSIF v_type = 'work' THEN
            -- Corporate IP derived from owner hash (unique per owner, /30)
            v_hash := abs(hashtext((rec.owner_account_id::text || 'corporate')::text));
            v_corporate_ip := (v_hash % 223 + 1)::int || '.' ||
                              ((v_hash / 256) % 256)::int || '.' ||
                              ((v_hash / 65536) % 256)::int || '.' ||
                              ((floor((v_hash / 16777216) % 64) * 4)::int)::int || '/30';
            INSERT INTO service.ip_permission (read_permission, write_permission, create_permission, delete_permission, priority, ip_mask, group_id)
            VALUES ('Grant', 'Grant', 'Grant', 'Grant', 1, v_corporate_ip::cidr, rec.id);

        ELSIF v_type = 'friends' THEN
            -- A few accounts: read + edit (Grant read/write, deny create/delete)
            INSERT INTO service.account_permission (account_id, read_permission, write_permission, create_permission, delete_permission, group_id)
            SELECT a.id, TRUE, TRUE, FALSE, FALSE, rec.id
            FROM accounts.accounts a
            ORDER BY random()
            LIMIT 3;

        ELSIF v_type = 'public' THEN
            -- All IPs read only
            INSERT INTO service.ip_permission (read_permission, write_permission, create_permission, delete_permission, priority, ip_mask, group_id)
            VALUES ('Grant', 'Deny', 'Deny', 'Deny', 1, '0.0.0.0/0', rec.id);

        ELSIF v_type = 'private' THEN
            -- Explicit deny for all IPs
            INSERT INTO service.ip_permission (read_permission, write_permission, create_permission, delete_permission, priority, ip_mask, group_id)
            VALUES ('Deny', 'Deny', 'Deny', 'Deny', 1, '0.0.0.0/0', rec.id);
        END IF;
    END LOOP;

    RAISE NOTICE 'Generated permissions for file groups';
END $$;