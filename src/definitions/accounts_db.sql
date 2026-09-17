-- accounts_db.sql
-- Creates tables for the accounts schema
-- Can be run with: psql -U datawarehouse_user -d datawarehouse -f src/definitions/accounts_db.sql

SET search_path TO accounts, public;

BEGIN;

CREATE TABLE accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_name VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    country VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    street VARCHAR(255),
    house_number VARCHAR(20),
    house_number_suffix VARCHAR(10),
    trial_used BOOLEAN NOT NULL DEFAULT FALSE,
    agb_version VARCHAR(50)
);

CREATE TABLE password (
    account_id UUID PRIMARY KEY REFERENCES accounts(id) ON DELETE CASCADE,
    hash BYTEA NOT NULL,
    salt BYTEA NOT NULL
);

CREATE TABLE payment_details (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    method VARCHAR(100) NOT NULL,
    amount DECIMAL(20, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    status VARCHAR(50) NOT NULL,
    transaction_reference VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE abo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    plan VARCHAR(100) NOT NULL CHECK (TRUE), -- TODO limit plan choice
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    auto_renew BOOLEAN NOT NULL DEFAULT FALSE,
    payment_details_id UUID NOT NULL REFERENCES payment_details(id)
);

CREATE TABLE payment_log_row (
    timestamp TIMESTAMP PRIMARY KEY,
    abo_id UUID NOT NULL REFERENCES abo(id) ON DELETE CASCADE,
    payment_details_id UUID NOT NULL REFERENCES payment_details(id),
    amount DECIMAL(20, 2) NOT NULL,
    was_auto_renew BOOLEAN NOT NULL DEFAULT FALSE,
    confirmation_email_id VARCHAR(255) NOT NULL,
    UNIQUE(abo_id, timestamp)
);

COMMIT;