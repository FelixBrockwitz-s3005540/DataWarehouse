-- Procedural file population for file table
-- Generates ~100 files (2 per account that has an accounts.abo)
-- Owners must have an accounts.abo (we join accounts with accounts.abo)
-- Size is in bytes (random between 1MB and 10GB, inclusive)
-- file_path is user-facing and organized like '/photos/2025/file_1234.jpg'
-- Other fields are filled with plausible values


DO $$
DECLARE
    v_owner_account RECORD;
    v_instance_id varchar(255);
    v_file_id uuid;
    v_file_name varchar(255);
    v_file_path varchar(255);
    v_size bigint;
    v_created_at timestamp;
    v_modified_at timestamp;
    v_last_download_at timestamp;
    v_created_by varchar(255);
    v_modified_by varchar(255);
    v_folder varchar(50);
    v_extension varchar(10);
    low_size bigint := 1048576;    -- 1MB in bytes
    high_size bigint := 10737418240; -- 10GB in bytes
BEGIN
    -- Truncate file table and any dependent tables (file_group) to avoid FK issues on re-run
    TRUNCATE TABLE service.file RESTART IDENTITY CASCADE;

    FOR v_owner_account IN
        SELECT a.id, a.user_name
        FROM accounts.accounts a
        WHERE EXISTS (SELECT 1 FROM accounts.abo WHERE abo.account_id = a.id)
    LOOP
        -- Generate 2 files per account to get ~100 files (50 accounts * 2 = 100)
        FOR i IN 1..2 LOOP
            -- Pick a random instance
            SELECT id INTO v_instance_id
            FROM service.instance
            ORDER BY random()
            LIMIT 1;

            -- Generate our own file UUID for the database primary key
            v_file_id := gen_random_uuid();

            -- Generate file name and user-facing folder path
            CASE floor(random() * 3)::int
                WHEN 0 THEN
                    v_folder := 'photos';
                    v_extension := '.jpg';
                WHEN 1 THEN
                    v_folder := 'documents';
                    v_extension := CASE WHEN random() < 0.5 THEN '.pdf' ELSE '.docx' END;
                ELSE
                    v_folder := 'videos';
                    v_extension := '.mp4';
            END CASE;

            v_file_name := 'file_' || floor(random() * 10000)::text || v_extension;

            -- Generate timestamps before building the user-facing path
            v_created_at := timestamp '2023-01-01' + 
                            (random() * (current_timestamp - timestamp '2023-01-01'));
            v_modified_at := v_created_at + 
                            (random() * (current_timestamp - v_created_at));
            v_last_download_at := CASE WHEN random() < 0.3 THEN NULL
                                    ELSE v_created_at + (random() * (current_timestamp - v_created_at))
                                END;

            -- User-facing path, e.g. '/photos/2025/file_1234.jpg'
            v_file_path := '/' || v_folder || '/' || EXTRACT(YEAR FROM v_created_at)::int::text || '/' || v_file_name;

            -- Generate size in bytes (between 1MB and 10GB, inclusive)
            -- Uses precomputed constants to avoid integer overflow in arithmetic
            v_size := floor(random() * (high_size - low_size + 1))::bigint + low_size;

            -- Set created_by and modified_by to the owner's user_name
            v_created_by := v_owner_account.user_name;
            v_modified_by := v_owner_account.user_name;

            -- Insert the file with explicit id
            INSERT INTO service.file (
                id,
                instance_id,
                owner_account_id,
                file_name,
                file_path,
                size,
                created_at,
                modified_at,
                last_download_at,
                created_by,
                modified_by
            ) VALUES (
                v_file_id,
                v_instance_id,
                v_owner_account.id,
                v_file_name,
                v_file_path,
                v_size,
                v_created_at,
                v_modified_at,
                v_last_download_at,
                v_created_by,
                v_modified_by
            );
        END LOOP;
    END LOOP;

    RAISE NOTICE 'Generated % files', (SELECT count(*) FROM service.file);
END $$;