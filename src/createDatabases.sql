-- createDatabases.sql
-- Creates the single database with schemas for the DataWarehouse project.
-- Reusable on the same PostgreSQL instance.
--
-- PostgreSQL limitations respected:
--   * Database / role names follow the rules: start with a letter,
--     contain only letters, digits and underscores, max 63 characters.
--   * Unquoted identifiers are case-folded to lowercase by postgres, so the
--     names are written in lowercase to avoid surprises.
--
-- Run with:  psql -U <adminuser> -f src/createDatabases.sql
-- The connecting user must have CREATEDB privilege.

-- ---------------------------------------------------------------------------
-- Role
-- ---------------------------------------------------------------------------
CREATE ROLE datawarehouse_user
    LOGIN
    PASSWORD 'datawarehouse_user';

-- ---------------------------------------------------------------------------
-- Database
-- ---------------------------------------------------------------------------
CREATE DATABASE datawarehouse
    OWNER datawarehouse_user;

-- ---------------------------------------------------------------------------
-- Schemas (run inside the database)
-- ---------------------------------------------------------------------------
\connect datawarehouse

-- Extension for UUID generation
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Accounts schema — user data, passwords, subscriptions, payments
CREATE SCHEMA accounts;

-- Service schema — instances, files, permissions
CREATE SCHEMA service;

-- Logs schema — access and performance logs
CREATE SCHEMA logs;

-- Grant permissions to datawarehouse_user on all schemas
GRANT USAGE ON SCHEMA accounts TO datawarehouse_user;
GRANT USAGE ON SCHEMA service TO datawarehouse_user;
GRANT USAGE ON SCHEMA logs TO datawarehouse_user;

GRANT CREATE ON SCHEMA accounts TO datawarehouse_user;
GRANT CREATE ON SCHEMA service TO datawarehouse_user;
GRANT CREATE ON SCHEMA logs TO datawarehouse_user;
