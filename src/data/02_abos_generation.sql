-- Procedural ABOS (abonnement) population for accounts table
-- Generates 50 ABOS for existing accounts:
--   - ~10 expired (end_date in the past), the rest active
--   - random start dates relative to script execution time
--   - plan durations exactly to spec (docs/Lizenzmodelle.txt):
--       Trialversion       1 Monat
--       Standard Private   1 Monat
--       Standard Group     1 Jahr
--       Premium            1 Jahr
--       Standard Enterprise 1 Jahr
--       Premium Enterprise 3 Jahre
--       Standard Authority 1 Jahr
--       Premium Authority  3 Jahre
--       Freeversion        unbegrenzt
--   - Free/Trial plans have NO payment details attached (NULL)
--   - Paid plans each get their OWN fresh accounts.payment_details row (never reused)
--   - Trial (and Free) plans never auto-renew


DO $$
DECLARE
    v_account_id uuid;
    v_plan accounts.plan_type;
    v_start_date timestamp;
    v_end_date timestamp;
    v_auto_renew boolean;
    v_payment_details_id uuid;
    v_duration interval;
    v_duration_days int;
    v_expired_target constant int := 10;
    v_expired_count int := 0;
    v_count int := 0;
BEGIN
    FOR v_account_id IN SELECT id FROM accounts.accounts ORDER BY id LIMIT 50
    LOOP
        -- Randomly choose a plan type
        v_plan := CASE (floor(random() * 9)::int)
            WHEN 0 THEN 'Freeversion'::accounts.plan_type
            WHEN 1 THEN 'Trialversion'::accounts.plan_type
            WHEN 2 THEN 'Standard Private'::accounts.plan_type
            WHEN 3 THEN 'Standard Group'::accounts.plan_type
            WHEN 4 THEN 'Premium'::accounts.plan_type
            WHEN 5 THEN 'Standard Enterprise'::accounts.plan_type
            WHEN 6 THEN 'Premium Enterprise'::accounts.plan_type
            WHEN 7 THEN 'Standard Authority'::accounts.plan_type
            WHEN 8 THEN 'Premium Authority'::accounts.plan_type
        END;

        -- Plan duration exactly to spec
        v_duration := CASE v_plan
            WHEN 'Freeversion'         THEN INTERVAL '100 years'  -- unbegrenzt
            WHEN 'Trialversion'        THEN INTERVAL '1 month'
            WHEN 'Standard Private'    THEN INTERVAL '1 month'
            WHEN 'Standard Group'      THEN INTERVAL '1 year'
            WHEN 'Premium'             THEN INTERVAL '1 year'
            WHEN 'Standard Enterprise' THEN INTERVAL '1 year'
            WHEN 'Premium Enterprise'  THEN INTERVAL '3 years'
            WHEN 'Standard Authority'  THEN INTERVAL '1 year'
            WHEN 'Premium Authority'   THEN INTERVAL '3 years'
        END;
        v_duration_days := EXTRACT(DAY FROM v_duration)::int
                         + 30 * EXTRACT(MONTH FROM v_duration)::int
                         + 365 * EXTRACT(YEAR FROM v_duration)::int;

        IF v_plan = 'Freeversion' THEN
            -- Unbegrenzt: random start in the past, far-future end -> always active
            v_start_date := CURRENT_TIMESTAMP - (random() * v_duration_days)::int * INTERVAL '1 day';
            v_end_date   := CURRENT_TIMESTAMP + INTERVAL '100 years';
        ELSIF v_expired_count < v_expired_target THEN
            -- Expired: pick random end_date in the past (1 day .. 12 months ago),
            -- start = end - duration so the length is still exactly to spec
            v_end_date   := CURRENT_TIMESTAMP - ((random() * 364)::int + 1) * INTERVAL '1 day';
            v_start_date := v_end_date - v_duration;
            v_expired_count := v_expired_count + 1;
        ELSE
            -- Active: random start in the past such that end = start + duration
            -- is always in the future (start at least 15 days before expiry)
            v_start_date := CURRENT_TIMESTAMP
                            - ((random() * (v_duration_days - 15))::int + 1) * INTERVAL '1 day';
            v_end_date   := v_start_date + v_duration;
        END IF;

        IF v_plan = 'Trialversion' THEN
            UPDATE accounts.accounts
            SET
                trial_used = TRUE
            WHERE
                id = v_account_id;
        END IF;

        -- Payment details: only paid plans get one, and each gets a FRESH row
        -- (inserted here), so no accounts.payment_details is ever reused.
        IF v_plan IN ('Freeversion', 'Trialversion') THEN
            v_payment_details_id := NULL;
        ELSE
            INSERT INTO accounts.payment_details (method, amount, currency, status, transaction_reference)
            VALUES (
                (ARRAY['credit_card', 'paypal', 'sepa_debit', 'invoice'])[floor(random() * 4)::int + 1],
                CASE v_plan
                    WHEN 'Standard Private'    THEN 10.00
                    WHEN 'Standard Group'      THEN 30.00
                    WHEN 'Premium'             THEN 50.00
                    WHEN 'Standard Enterprise' THEN 1000.00
                    WHEN 'Premium Enterprise'  THEN 2000.00
                    WHEN 'Standard Authority'  THEN 800.00
                    WHEN 'Premium Authority'   THEN 1600.00
                END,
                'EUR',
                CASE WHEN v_end_date < CURRENT_TIMESTAMP THEN 'expired' ELSE 'completed' END,
                'txn-' || gen_random_uuid()
            )
            RETURNING id INTO v_payment_details_id;
        END IF;

        -- auto_renew: only possible with payment details attached,
        -- and Trial plans never auto-renew
        v_auto_renew := (v_payment_details_id IS NOT NULL)
                        AND v_plan <> 'Trialversion'
                        AND (random() < 0.5);

        INSERT INTO accounts.abo (account_id, plan, start_date, end_date, auto_renew, payment_details_id)
        VALUES (v_account_id, v_plan, v_start_date, v_end_date, v_auto_renew, v_payment_details_id);

        v_count := v_count + 1;
    END LOOP;

    RAISE NOTICE 'Generated % ABOS (% expired, % active, % without payment details)',
        v_count, v_expired_count, v_count - v_expired_count,
        (SELECT count(*) FROM accounts.abo WHERE payment_details_id IS NULL);
END $$;