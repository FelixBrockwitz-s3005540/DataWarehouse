-- Procedural file_group population for file_group + file_to_group tables
-- Rules respected:
--   * a file can be in many groups (each file gets 1 primary + chance of a second group)
--   * many files can be in one group (all of an owner's files are candidates)
--   * each group only contains files from one owner (files explicitly attached to a group
--     must belong to the same owner as the group)
--   * glob_pattern is optional; a group can be glob-only (no explicit files attached)
--   * explicitly attached files do not need to match the glob pattern

DO $$
DECLARE
    v_owner RECORD;
    v_file_ids uuid[];
    v_file_id uuid;
    v_group_count int := 4;
    v_group_types text[] := ARRAY['family', 'work', 'friends', 'public', 'archive', 'private'];
    v_picked_types text[];
    v_group_name varchar(100);
    v_group_id uuid;
    v_group_ids uuid[];
    g int;
    v_g int;
    v_g2 int;
BEGIN
    -- Truncate dependent table first, then file_group
    TRUNCATE TABLE service.file_to_group CASCADE;
    TRUNCATE TABLE service.file_group RESTART IDENTITY CASCADE;

    FOR v_owner IN
        SELECT a.id, a.user_name
        FROM accounts.accounts a
        WHERE EXISTS (SELECT 1 FROM accounts.abo WHERE abo.account_id = a.id)
    LOOP
        -- Collect this owner's files; skip owners that have none
        SELECT array_agg(id) INTO v_file_ids
        FROM service.file
        WHERE owner_account_id = v_owner.id;

        CONTINUE WHEN v_file_ids IS NULL;

        -- Each owner gets 2 groups with distinct, random types
        -- (unnest must be in FROM: in the target list all rows would share one
        -- random() value and the shuffle would be a no-op)
        SELECT array_agg(t) INTO v_picked_types
        FROM (
            SELECT t FROM unnest(v_group_types) AS t
            ORDER BY random()
            LIMIT v_group_count
        ) s;

        v_group_ids := ARRAY[]::uuid[];
        FOR g IN 1..v_group_count LOOP
            -- Group name: user_name_type (e.g. john_doe_family), globally unique per owner
            v_group_name := left(v_owner.user_name, 30) || '_' || v_picked_types[g];

            -- Sensible glob_pattern: match all files under the category (or all files for public/private)
            INSERT INTO service.file_group (name, owner_account_id, glob_pattern)
            VALUES (
                v_group_name,
                v_owner.id,
                CASE v_picked_types[g]
                    WHEN 'family' THEN '/photos/%'
                    WHEN 'work' THEN '/documents/%'
                    WHEN 'friends' THEN NULL
                    WHEN 'public' THEN '%'
                    WHEN 'archive' THEN '/archive/%'
                    WHEN 'private' THEN '%'
                    ELSE NULL
                END
            )
            RETURNING id INTO v_group_id;

            v_group_ids[g] := v_group_id;
        END LOOP;

        -- Assign each of the owner's files to 1 or 2 of their groups,
        -- spread randomly across ALL groups (explicitly attached files
        -- belong to the same owner as the group)
        FOR v_file_id IN SELECT unnest(v_file_ids) LOOP
            -- Primary group: random one of the owner's groups
            v_g := 1 + floor(random() * v_group_count)::int;
            INSERT INTO service.file_to_group (file_id, group_id)
            VALUES (v_file_id, v_group_ids[v_g])
            ON CONFLICT (file_id, group_id) DO NOTHING;

            -- 50% chance the file is also in a second, different group
            -- (a file can be in many groups)
            IF random() < 0.5 THEN
                v_g2 := 1 + floor(random() * (v_group_count - 1))::int;
                IF v_g2 >= v_g THEN
                    v_g2 := v_g2 + 1;
                END IF;
                INSERT INTO service.file_to_group (file_id, group_id)
                VALUES (v_file_id, v_group_ids[v_g2])
                ON CONFLICT (file_id, group_id) DO NOTHING;
            END IF;
        END LOOP;
    END LOOP;

    -- Same rule as the auto-cleanup trigger: a glob-less group with no files
    -- can never match anything, so drop it right after generation
    DELETE FROM service.file_group g
    WHERE g.glob_pattern IS NULL
      AND NOT EXISTS (SELECT 1 FROM service.file_to_group ftg WHERE ftg.group_id = g.id);

    RAISE NOTICE 'Generated % file-to-group memberships',
        (SELECT count(*) FROM service.file_to_group);
END $$;