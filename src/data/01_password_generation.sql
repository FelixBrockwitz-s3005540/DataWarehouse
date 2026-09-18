-- Procedural password population for accounts table
-- Generates random BYTEA hash and salt for each account using gen_random_bytes
-- Runs after accounts are populated
-- Requires pgcrypto extension (already created in createDatabases.sql)


DO $$
DECLARE
    v_account uuid;
    v_hash bytea;
    v_salt bytea;
BEGIN
    FOR v_account IN SELECT id FROM accounts.accounts
    LOOP
        v_hash := gen_random_bytes(16);
        v_salt := gen_random_bytes(16);
        INSERT INTO accounts.password (account_id, hash, salt) 
        VALUES (v_account, v_hash, v_salt);
    END LOOP;
END$$;