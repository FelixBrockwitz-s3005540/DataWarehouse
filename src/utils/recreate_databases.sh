#!/bin/bash

# Database recreation script for DataWarehouse project
# Deletes existing databases if they exist and executes scripts in correct order

# Set error handling
set -e

# Database and user names
ADMIN_USER="postgres"
USERNAME="datawarehouse_user"
ACCOUNTS_DB="accounts_db"
SERVICE_DB="service_db"
LOGS_DB="logs_db"

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
        psql -U "$ADMIN_USER" -c "REVOKE ALL ON DATABASE $ACCOUNTS_DB FROM \"$username\";" > /dev/null 2>&1 || true
        psql -U "$ADMIN_USER" -c "REVOKE ALL ON DATABASE $SERVICE_DB FROM \"$username\";" > /dev/null 2>&1 || true
        psql -U "$ADMIN_USER" -c "REVOKE ALL ON DATABASE $LOGS_DB FROM \"$username\";" > /dev/null 2>&1 || true
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
    psql -U "$user" -d "$db_name" -f "$sql_file"

    if [ $? -eq 0 ]; then
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
drop_database "$LOGS_DB"
drop_database "$SERVICE_DB"
drop_database "$ACCOUNTS_DB"

# Drop user
drop_user "$USERNAME"

# Step 2: Create databases and user
print_info "=== Step 2: Creating databases and user ==="

print_info "Creating databases and user (this may take a moment)..."
psql -U "$ADMIN_USER" -f "src/createDatabases.sql"

if [ $? -eq 0 ]; then
    print_info "Successfully created databases and user."
else
    print_error "Failed to create databases and user."
    exit 1
fi

# Step 2.5: Create postgres_fdw extension in each database (requires superuser)
print_info "=== Step 2.5: Creating postgres_fdw extension ==="

for db in "$ACCOUNTS_DB" "$SERVICE_DB" "$LOGS_DB"; do
    print_info "Creating postgres_fdw extension in $db..."
    psql -U "$ADMIN_USER" -d "$db" -c "CREATE EXTENSION IF NOT EXISTS postgres_fdw;"

    if [ $? -eq 0 ]; then
        print_info "Successfully created extension in $db."
    else
        print_error "Failed to create extension in $db."
        exit 1
    fi

    # Grant USAGE on extension to datawarehouse_user
    psql -U "$ADMIN_USER" -d "$db" -c "GRANT USAGE ON FOREIGN DATA WRAPPER postgres_fdw TO $USERNAME;"
done

# Step 3: Set up cross-database references (requires superuser for CREATE SERVER)
print_info "=== Step 3: Setting up cross-database references ==="

run_sql_as "src/definitions/cross_db_references.sql" "$SERVICE_DB" "$ADMIN_USER" "Setting up cross-database references in service_db"

run_sql_as "src/definitions/cross_db_references.sql" "$LOGS_DB" "$ADMIN_USER" "Setting up cross-database references in logs_db"

# Step 4: Set up permissions for datawarehouse_user
print_info "=== Step 4: Setting up permissions ==="

for db in "$ACCOUNTS_DB" "$SERVICE_DB" "$LOGS_DB"; do
    print_info "Granting permissions to $USERNAME in $db..."
    psql -U "$ADMIN_USER" -d "$db" -c "GRANT ALL ON SCHEMA public TO $USERNAME;"
done

# Step 5: Execute table definition scripts
print_info "=== Step 5: Executing table definition scripts ==="

# Run definition scripts in the correct order
run_sql "src/definitions/accounts_db.sql" "$ACCOUNTS_DB" "Creating accounts tables"
run_sql "src/definitions/service_db.sql" "$SERVICE_DB" "Creating service tables"
run_sql "src/definitions/logs_db.sql" "$LOGS_DB" "Creating logs tables"

print_info "=== All databases have been successfully recreated ==="
print_info "Summary:"
print_info "- Databases: $ACCOUNTS_DB, $SERVICE_DB, $LOGS_DB"
print_info "- User: $USERNAME"
print_info "- Cross-database references set up"
print_info "- All table definitions applied"

exit 0
