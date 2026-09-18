#!/bin/bash

# Database recreation script for DataWarehouse project
# Deletes existing databases if they exist and executes scripts in correct order

# Set error handling
set -e

# Database and user names
ADMIN_USER="postgres"
USERNAME="datawarehouse_user"
DATAWAREHOUSE_DB="datawarehouse"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if database exists
database_exists() {
    psql -U "$ADMIN_USER" -lqt | cut -d \| -f 1 | grep -qw "$1"
}

# Function to drop database if it exists
drop_database() {
    local db_name=$1
    if database_exists "$db_name"; then
        print_info "Dropping database '$db_name' if it exists..."
        # Terminate connections to the database
        psql -U "$ADMIN_USER" -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$db_name';" > /dev/null 2>&1 || true
        # Drop the database
        dropdb -U "$ADMIN_USER" "$db_name" || true
        print_info "Database '$db_name' dropped."
    else
        print_info "Database '$db_name' does not exist."
    fi
}

# Function to drop user if it exists
drop_user() {
    local username=$1
    # Check if user exists by trying to list roles
    if psql -U "$ADMIN_USER" -qt -c "\du \"$username\"" | grep -q "$username"; then
        print_info "Dropping user '$username' if it exists..."
        # Revoke all privileges from the user
        psql -U "$ADMIN_USER" -c "REVOKE ALL ON DATABASE $DATAWAREHOUSE_DB FROM \"$username\";" > /dev/null 2>&1 || true
        # Drop the user
        dropuser -U "$ADMIN_USER" "$username" || true
        print_info "User '$username' dropped."
    else
        print_info "User '$username' does not exist."
    fi
}

# Function to run SQL file as a specific user
run_sql_as() {
    local sql_file=$1
    local db_name=$2
    local user=$3
    local description=$4

    print_info "$description..."
    echo "Running: $sql_file as $user"

    if psql -U "$user" -d "$db_name" -f "$sql_file" -v ON_ERROR_STOP=1 > /dev/null; then
        print_info "Successfully completed: $description"
    else
        print_error "Failed to execute: $description"
        exit 1
    fi
}

# Function to run SQL file as datawarehouse_user
run_sql() {
    run_sql_as "$1" "$2" "$USERNAME" "$3"
}

# Main execution

print_info "Starting database recreation process..."

# Step 1: Drop existing databases and user
print_info "=== Step 1: Cleaning up existing databases and user ==="

# Order matters - drop databases first
drop_database "$DATAWAREHOUSE_DB"

# Drop user
drop_user "$USERNAME"

# Step 2: Create database, schemas, and user
print_info "=== Step 2: Creating database and schemas ==="

print_info "Creating database, schemas, and user (this may take a moment)..."
if psql -U "$ADMIN_USER" -f "src/createDatabases.sql" -v ON_ERROR_STOP=1 > /dev/null; then
    print_info "Successfully created database, schemas, and user."
else
    print_error "Failed to create database, schemas, and user."
    exit 1
fi

# Step 3: Execute table definition scripts
print_info "=== Step 3: Executing table definition scripts ==="

# Run definition scripts in the correct order (search_path in each file determines schema)
run_sql "src/definitions/accounts_db.sql" "$DATAWAREHOUSE_DB" "Creating accounts tables"
run_sql "src/definitions/service_db.sql" "$DATAWAREHOUSE_DB" "Creating service tables"
run_sql "src/definitions/logs_db.sql" "$DATAWAREHOUSE_DB" "Creating logs tables"

# Step 4: Populate example data
print_info "=== Step 4: Populating example data ==="

# Clear existing data and insert ~100 rows for each table (excluding logs)
run_sql "src/data/00_accounts.sql" "$DATAWAREHOUSE_DB" "Clearing existing data and inserting example accounts"
run_sql "src/data/01_password_generation.sql" "$DATAWAREHOUSE_DB" "Generating passwords procedurally"
run_sql "src/data/02_abos_generation.sql" "$DATAWAREHOUSE_DB" "Generating ABOS for accounts"
run_sql "src/data/03_payment_log_row.sql" "$DATAWAREHOUSE_DB" "Generating payment logs"
run_sql "src/data/04_instance.sql" "$DATAWAREHOUSE_DB" "Inserting 20 service instances"
run_sql "src/data/05_file_generation.sql" "$DATAWAREHOUSE_DB" "Generating ~100 service files"
run_sql "src/data/06_file_group_generation.sql" "$DATAWAREHOUSE_DB" "Generating file groups for access permissions"
run_sql "src/data/07_file_permission_generation.sql" "$DATAWAREHOUSE_DB" "Generating file permissions"

print_info "=== Example data populated ==="

print_info "=== Database has been successfully recreated ==="
print_info "Summary:"
print_info "- Database: $DATAWAREHOUSE_DB"
print_info "- Schemas: accounts, service, logs"
print_info "- User: $USERNAME"
print_info "- All table definitions applied"

exit 0