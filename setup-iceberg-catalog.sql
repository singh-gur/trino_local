-- SQL script to setup Iceberg JDBC Catalog database
-- Run this script in your PostgreSQL database (e.g., via DBeaver)

-- 1. Create the database (if you haven't already)
-- Note: You might need to run this separately if you are not connected to a default DB
-- CREATE DATABASE iceberg_catalog;

-- 2. Create the tables required by Iceberg JDBC Catalog
-- These tables store the metadata for Iceberg tables and namespaces

CREATE TABLE IF NOT EXISTS iceberg_tables (
    catalog_name VARCHAR(255) NOT NULL,
    table_namespace VARCHAR(255) NOT NULL,
    table_name VARCHAR(255) NOT NULL,
    metadata_location VARCHAR(1000),
    previous_metadata_location VARCHAR(1000),
    PRIMARY KEY (catalog_name, table_namespace, table_name)
);

CREATE TABLE IF NOT EXISTS iceberg_namespace_properties (
    catalog_name VARCHAR(255) NOT NULL,
    namespace VARCHAR(255) NOT NULL,
    property_key VARCHAR(255) NOT NULL,
    property_value VARCHAR(1000),
    PRIMARY KEY (catalog_name, namespace, property_key)
);

-- 3. (Optional) Create a user for Trino
-- CREATE USER trino WITH PASSWORD 'trino';
-- GRANT ALL PRIVILEGES ON DATABASE iceberg_catalog TO trino;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO trino;
