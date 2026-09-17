-- cross_db_references.sql
-- Sets up postgres_fdw so tables in this database can reference tables in other databases.
-- Must be run BEFORE the definition scripts in each database that needs cross-database access.
--
-- Run in service_db:
--   psql -U datawarehouse_user -d service_db -f src/definitions/cross_db_references.sql
--
-- Run in logs_db:
--   psql -U datawarehouse_user -d logs_db -f src/definitions/cross_db_references.sql

-- ---------------------------------------------------------------------------
-- Foreign server pointing to accounts_db
-- ---------------------------------------------------------------------------
CREATE SERVER IF NOT EXISTS accounts_db_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', port '5432', dbname 'accounts_db');

CREATE USER MAPPING IF NOT EXISTS FOR CURRENT_USER
    SERVER accounts_db_server
    OPTIONS (user 'datawarehouse_user', password 'datawarehouse_user');

-- ---------------------------------------------------------------------------
-- Foreign server pointing to service_db (needed by logs_db)
-- ---------------------------------------------------------------------------
CREATE SERVER IF NOT EXISTS service_db_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', port '5432', dbname 'service_db');

CREATE USER MAPPING IF NOT EXISTS FOR CURRENT_USER
    SERVER service_db_server
    OPTIONS (user 'datawarehouse_user', password 'datawarehouse_user');

-- ---------------------------------------------------------------------------
-- Foreign tables for accounts (referenced from service_db and logs_db)
-- ---------------------------------------------------------------------------
CREATE FOREIGN TABLE IF NOT EXISTS accounts (
    id UUID,
    user_name VARCHAR(255),
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    country VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    street VARCHAR(255),
    house_number VARCHAR(20),
    house_number_suffix VARCHAR(10),
    trial_used BOOLEAN,
    agb_version VARCHAR(50)
)
SERVER accounts_db_server
OPTIONS (schema_name 'public', table_name 'accounts');

-- ---------------------------------------------------------------------------
-- Foreign table for instance (referenced from logs_db)
-- ---------------------------------------------------------------------------
CREATE FOREIGN TABLE IF NOT EXISTS instance (
    id SERIAL,
    region VARCHAR(100),
    system_version VARCHAR(100),
    cpu VARCHAR(100),
    max_ram_gb FLOAT,
    system_partition_gb FLOAT,
    files_partition_tb FLOAT,
    max_upload FLOAT,
    max_download FLOAT
)
SERVER service_db_server
OPTIONS (schema_name 'public', table_name 'instance');

-- ---------------------------------------------------------------------------
-- Foreign table for file (referenced from logs_db)
-- ---------------------------------------------------------------------------
CREATE FOREIGN TABLE IF NOT EXISTS file (
    id UUID,
    instance_id VARCHAR(255),
    owner_account_id UUID,
    file_name VARCHAR(255),
    file_path VARCHAR(255),
    size BIGINT,
    created_at TIMESTAMP,
    modified_at TIMESTAMP,
    last_download_at TIMESTAMP,
    created_by VARCHAR(255),
    modified_by VARCHAR(255)
)
SERVER service_db_server
OPTIONS (schema_name 'public', table_name 'file');
