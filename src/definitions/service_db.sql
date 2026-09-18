-- service_db.sql
-- Creates tables for the service schema
-- Can be run with: psql -U datawarehouse_user -d datawarehouse -f src/definitions/service_db.sql


BEGIN;

CREATE TABLE service.instance (
    id VARCHAR(255) PRIMARY KEY,
    region VARCHAR(100) NOT NULL,
    system_version VARCHAR(100) NOT NULL,
    cpu VARCHAR(100) NOT NULL,
    max_ram_gb FLOAT NOT NULL,
    system_partition_gb FLOAT NOT NULL,
    files_partition_tb FLOAT NOT NULL,
    max_upload FLOAT NOT NULL,
    max_download FLOAT NOT NULL
);

CREATE TABLE service.file (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instance_id VARCHAR(255) NOT NULL REFERENCES service.instance(id),
    owner_account_id UUID NOT NULL REFERENCES accounts.accounts(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(255) NOT NULL,
    size BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL,
    modified_at TIMESTAMP NOT NULL,
    last_download_at TIMESTAMP,
    created_by VARCHAR(255) NOT NULL,
    modified_by VARCHAR(255) NOT NULL,
    UNIQUE(owner_account_id, file_path)
);

CREATE TABLE service.file_group (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    owner_account_id UUID NOT NULL REFERENCES accounts.accounts(id) ON DELETE CASCADE,
    glob_pattern VARCHAR(100),
    UNIQUE(name, owner_account_id)
);

CREATE TABLE service.file_to_group (
    file_id UUID NOT NULL REFERENCES service.file(id) ON DELETE CASCADE,
    group_id UUID NOT NULL REFERENCES service.file_group(id) ON DELETE CASCADE,
    PRIMARY KEY (file_id, group_id)
);

CREATE TABLE service.ip_permission (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    read_permission VARCHAR(10) NOT NULL CHECK (read_permission IN ('Grant', 'Deny')),
    write_permission VARCHAR(10) NOT NULL CHECK (write_permission IN ('Grant', 'Deny')),
    create_permission VARCHAR(10) NOT NULL CHECK (create_permission IN ('Grant', 'Deny')),
    delete_permission VARCHAR(10) NOT NULL CHECK (delete_permission IN ('Grant', 'Deny')),
    priority INTEGER NOT NULL,
    -- Fused: ipv4_address + v4_subnet_mask + ipv6_address + v6_subnet_mask → single cidr with embedded netmask
    ip_mask CIDR,
    group_id UUID NOT NULL REFERENCES service.file_group(id),
    UNIQUE(priority, group_id)
);

CREATE TABLE service.account_permission (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES accounts.accounts(id) ON DELETE CASCADE,
    read_permission BOOLEAN NOT NULL DEFAULT FALSE,
    write_permission BOOLEAN NOT NULL DEFAULT FALSE,
    create_permission BOOLEAN NOT NULL DEFAULT FALSE,
    delete_permission BOOLEAN NOT NULL DEFAULT FALSE,
    group_id UUID NOT NULL REFERENCES service.file_group(id)
);

COMMIT;
