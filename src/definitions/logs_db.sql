-- logs_db.sql
-- Creates tables for the logs schema
-- Can be run with: psql -U datawarehouse_user -d datawarehouse -f src/definitions/logs_db.sql


BEGIN;

CREATE TYPE logs.instance_status AS ENUM ('online', 'offline', 'degraded', 'maintenance', 'unknown');

CREATE TYPE logs.operation_type AS ENUM ('read', 'write', 'create', 'delete');

CREATE TABLE logs.access_log_row (
    timestamp TIMESTAMP NOT NULL,
    account_id UUID REFERENCES accounts.accounts(id),
    ip_address INET,
    file_id UUID NOT NULL REFERENCES service.file(id),
    operation_type logs.operation_type NOT NULL,
    PRIMARY KEY(file_id, timestamp),
    CHECK (ip_address IS NOT NULL OR account_id IS NOT NULL)
);

CREATE TABLE logs.performance_log_row (
    timestamp TIMESTAMP NOT NULL,
    instance_id VARCHAR(255) NOT NULL REFERENCES service.instance(id),
    status logs.instance_status NOT NULL,
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