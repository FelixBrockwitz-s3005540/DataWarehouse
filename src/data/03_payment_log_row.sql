-- Procedural payment_log_row population
-- Generates ~1000 payment log entries for paid abos (Free/Trial have no
-- payment details, so they produce no payment logs).
--
-- Assumptions that keep the data plausible:
--   - Every paid abo is billed MONTHLY at the plan price from Lizenzmodelle.txt
--     (stored on its payment_details row, which we reuse here).
--   - The log covers the billing HISTORY of each abo: one entry per month,
--     going backwards from now. Entries older than the current abo's
--     start_date represent renewal payments from previous subscription
--     periods of the same customer.
--   - was_auto_renew is TRUE for renewal payments of abos that have
--     auto_renew enabled; the initial payment of a period is FALSE.
--   - Each log gets a unique confirmation email id.

SET search_path TO accounts, public;

DO $$
DECLARE
    rec RECORD;
    v_k int;
    v_n int;
    v_base_day int;
    v_base_hour int;
    v_base_minute int;
    v_ts timestamp;
    v_now timestamp := CURRENT_TIMESTAMP;
    v_count int;
BEGIN
    FOR rec IN
        SELECT a.id AS abo_id,
               a.start_date,
               a.auto_renew,
               pd.id AS pd_id,
               pd.amount
        FROM abo a
        JOIN payment_details pd ON pd.id = a.payment_details_id
        WHERE a.plan NOT IN ('Freeversion', 'Trialversion')
    LOOP
        -- 15..40 monthly payments per paid abo -> ~1000 rows overall
        v_n := 15 + floor(random() * 26)::int;
        -- Random anchor day/hour of the month so payment dates differ per abo
        v_base_day := floor(random() * 26)::int;
        v_base_hour := floor(random() * 24)::int;
        v_base_minute := floor(random() * 60)::int;

        FOR v_k IN 0..v_n - 1 LOOP
            v_ts := date_trunc('month', v_now)
                    - (v_k * INTERVAL '1 month')
                    + (v_base_day * INTERVAL '1 day')
                    + (v_base_hour * INTERVAL '1 hour')
                    + (v_base_minute * INTERVAL '1 minute');

            -- Don't log payments "from the future"
            IF v_ts > v_now THEN
                CONTINUE;
            END IF;

            INSERT INTO payment_log_row (timestamp, abo_id, payment_details_id,
                                         amount, was_auto_renew, confirmation_email_id)
            VALUES (v_ts,
                    rec.abo_id,
                    rec.pd_id,
                    rec.amount,
                    (v_k > 0 AND rec.auto_renew),
                    'confirm-' || gen_random_uuid())
            ON CONFLICT DO NOTHING;
        END LOOP;
    END LOOP;

    SELECT count(*) INTO v_count FROM payment_log_row;
    RAISE NOTICE 'Generated % payment log rows', v_count;
END $$;