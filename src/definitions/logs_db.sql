-- logs_db.sql
-- Creates tables for the Logs DB
-- Can be run with: psql -U datawarehouse_user -d logs_db -f src/definitions/logs_db.sql

BEGIN;

CREATE TABLE access_log_row (
    timestamp TIMESTAMP NOT NULL,
    account_id UUID REFERENCES accounts(id),
    ip_address INET,
    file_id UUID NOT NULL REFERENCES file(id) ON DELETE CASCADE,
    operation_type VARCHAR(100) NOT NULL,
    PRIMARY KEY(file_id, timestamp)
);

CREATE TABLE performance_log_row (
    timestamp TIMESTAMP NOT NULL,
    instance_id VARCHAR(255) NOT NULL REFERENCES instance(id),
    status VARCHAR(50) NOT NULL,
    cpu_percent FLOAT NOT NULL,
    ram_gb FLOAT NOT NULL,
    system_storage_gb FLOAT NOT NULL,
    file_storage_tb FLOAT NOT NULL,
    network_upload FLOAT NOT NULL,
    network_download FLOAT NOT NULL,
    cpu_temp FLOAT NOT NULL,
    disk_temp FLOAT NOT NULL,
    environment_temp FLOAT NOT NULL,
    PRIMARY KEY(timestamp, instance_id)
);

COMMIT;
