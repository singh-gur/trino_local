-- Sample Trino Queries for Iceberg Tables
-- Execute with: just query-file examples/sample-queries.sql

-- Show all available catalogs
SHOW CATALOGS;

-- Show schemas in the iceberg catalog
SHOW SCHEMAS FROM iceberg;

-- Create a new schema
CREATE SCHEMA IF NOT EXISTS iceberg.examples;

-- Show tables in the examples schema
SHOW TABLES FROM iceberg.examples;

-- Create a sample customers table
-- Note: Replace 'my-bucket' with your actual S3 bucket name
CREATE TABLE IF NOT EXISTS iceberg.examples.customers (
    customer_id BIGINT,
    first_name VARCHAR,
    last_name VARCHAR,
    email VARCHAR,
    country VARCHAR,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
) WITH (
    format = 'PARQUET',
    location = 's3a://my-bucket/examples/customers'
);

-- Insert sample customer data
INSERT INTO iceberg.examples.customers VALUES
    (1, 'John', 'Doe', 'john.doe@example.com', 'USA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (2, 'Jane', 'Smith', 'jane.smith@example.com', 'UK', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (3, 'Bob', 'Johnson', 'bob.johnson@example.com', 'Canada', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (4, 'Alice', 'Williams', 'alice.williams@example.com', 'Australia', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (5, 'Charlie', 'Brown', 'charlie.brown@example.com', 'USA', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Query all customers
SELECT * FROM iceberg.examples.customers;

-- Query customers by country
SELECT * FROM iceberg.examples.customers WHERE country = 'USA';

-- Count customers by country
SELECT country, COUNT(*) as customer_count 
FROM iceberg.examples.customers 
GROUP BY country 
ORDER BY customer_count DESC;

-- Create a sample orders table
CREATE TABLE IF NOT EXISTS iceberg.examples.orders (
    order_id BIGINT,
    customer_id BIGINT,
    product_name VARCHAR,
    quantity INTEGER,
    price DECIMAL(10, 2),
    order_date TIMESTAMP
) WITH (
    format = 'PARQUET',
    location = 's3a://my-bucket/examples/orders',
    partitioning = ARRAY['day(order_date)']
);

-- Insert sample order data
INSERT INTO iceberg.examples.orders VALUES
    (101, 1, 'Laptop', 1, 999.99, CURRENT_TIMESTAMP),
    (102, 1, 'Mouse', 2, 29.99, CURRENT_TIMESTAMP),
    (103, 2, 'Keyboard', 1, 79.99, CURRENT_TIMESTAMP),
    (104, 3, 'Monitor', 2, 299.99, CURRENT_TIMESTAMP),
    (105, 4, 'Headphones', 1, 149.99, CURRENT_TIMESTAMP),
    (106, 5, 'Webcam', 1, 89.99, CURRENT_TIMESTAMP);

-- Query all orders
SELECT * FROM iceberg.examples.orders;

-- Join customers with their orders
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    o.order_id,
    o.product_name,
    o.quantity,
    o.price,
    o.order_date
FROM iceberg.examples.customers c
JOIN iceberg.examples.orders o ON c.customer_id = o.customer_id
ORDER BY o.order_date DESC;

-- Calculate total order value per customer
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(o.order_id) as total_orders,
    SUM(o.quantity * o.price) as total_spent
FROM iceberg.examples.customers c
LEFT JOIN iceberg.examples.orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC;

-- Show table metadata
SELECT * FROM iceberg.examples."customers$snapshots";

-- Show table files
SELECT * FROM iceberg.examples."customers$files";

-- Show table history
SELECT * FROM iceberg.examples."customers$history";

-- Update a customer record (Iceberg supports updates!)
UPDATE iceberg.examples.customers 
SET email = 'john.newemail@example.com', updated_at = CURRENT_TIMESTAMP 
WHERE customer_id = 1;

-- Verify the update
SELECT * FROM iceberg.examples.customers WHERE customer_id = 1;

-- Delete a customer (Iceberg supports deletes!)
DELETE FROM iceberg.examples.customers WHERE customer_id = 5;

-- Verify the deletion
SELECT * FROM iceberg.examples.customers;

-- Time travel: Query table as of a specific snapshot
-- (Replace snapshot_id with actual snapshot ID from $snapshots table)
-- SELECT * FROM iceberg.examples.customers FOR VERSION AS OF 1234567890;

-- Show table statistics
SHOW STATS FOR iceberg.examples.customers;

-- Optimize table (compact small files)
-- ALTER TABLE iceberg.examples.customers EXECUTE optimize;

-- Expire old snapshots (cleanup)
-- ALTER TABLE iceberg.examples.customers EXECUTE expire_snapshots(retention_threshold => '7d');
