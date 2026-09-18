-- Account duplication generator
-- Duplicates every base account from 00_accounts.sql 9 times (10x total),
-- appending a number to the unique parts (user_name, email) to keep them valid:
--   'John Doe'  -> 'John Doe 1' ... 'John Doe 9'
--   'john.doe@example.com' -> 'john.doe1@example.com' ... 'john.doe9@example.com'
-- Idempotent: previously generated duplicates (user_name ending in ' <digits>')
-- are removed before re-duplicating.

DO $$
DECLARE
    v_copies constant int := 9;
    v_new_rows int;
BEGIN
    -- Idempotency guard: drop previously generated duplicates
    DELETE FROM accounts.accounts WHERE user_name ~ ' \d+$';

    INSERT INTO accounts.accounts
        (user_name, first_name, last_name, email, phone, country, city,
         postal_code, street, house_number, house_number_suffix, trial_used, agb_version)
    SELECT
        left(a.user_name, 245) || ' ' || d.i,
        a.first_name,
        a.last_name,
        left(split_part(a.email, '@', 1), 200) || d.i || '@' || split_part(a.email, '@', 2),
        a.phone,
        a.country,
        a.city,
        a.postal_code,
        a.street,
        a.house_number,
        a.house_number_suffix,
        a.trial_used,
        a.agb_version
    FROM accounts.accounts a
    CROSS JOIN generate_series(1, v_copies) AS d(i)
    WHERE a.user_name !~ ' \d+$';

    GET DIAGNOSTICS v_new_rows = ROW_COUNT;
    RAISE NOTICE 'Created % duplicated accounts (% total)',
        v_new_rows, (SELECT count(*) FROM accounts.accounts);
END $$;