-- Exercise 02: Remove duplicates from customers table (Simple & Reliable)
-- Run this AFTER ex01_customers_table.sql

-- Check if customers table exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'customers') THEN
        RAISE EXCEPTION 'customers table not found! Please run ex01_customers_table.sql first';
    END IF;
    RAISE NOTICE 'customers table found, proceeding with duplicate removal';
END;
$$;

-- Show current row count
SELECT COUNT(*) as rows_before_cleanup FROM customers;

-- Create backup table
DROP TABLE IF EXISTS customers_backup;
CREATE TABLE customers_backup AS SELECT * FROM customers;

-- Notify backup created
DO $$
BEGIN
    RAISE NOTICE 'Backup created: customers_backup';
END;
$$;

-- Find duplicates (same user_id, product_id, event_type, price within same second)
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT (user_id, product_id, event_type, price, date_trunc('second', event_time))) as unique_combinations,
    COUNT(*) - COUNT(DISTINCT (user_id, product_id, event_type, price, date_trunc('second', event_time))) as duplicates_found
FROM customers;

-- Remove duplicates - keep the earliest occurrence
DELETE FROM customers 
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM customers
    GROUP BY user_id, product_id, event_type, price, date_trunc('second', event_time)
);

-- Show results
SELECT 
    (SELECT COUNT(*) FROM customers_backup) as original_rows,
    COUNT(*) as cleaned_rows,
    (SELECT COUNT(*) FROM customers_backup) - COUNT(*) as duplicates_removed
FROM customers;

-- Verify no duplicates remain
WITH duplicate_check AS (
    SELECT 
        user_id, product_id, event_type, price, date_trunc('second', event_time) as event_second,
        COUNT(*) as count_per_group
    FROM customers 
    GROUP BY user_id, product_id, event_type, price, date_trunc('second', event_time)
    HAVING COUNT(*) > 1
)
SELECT 
    CASE WHEN COUNT(*) = 0 
         THEN 'SUCCESS: No duplicates remaining' 
         ELSE 'WARNING: ' || COUNT(*) || ' duplicate groups still exist' 
    END as verification_result
FROM duplicate_check;

-- Create unique index to prevent future duplicates
DROP INDEX IF EXISTS idx_customers_no_duplicates;
CREATE UNIQUE INDEX idx_customers_no_duplicates 
ON customers (user_id, product_id, event_type, price, date_trunc('second', event_time));

-- Show sample of final data
SELECT 
    event_time,
    event_type, 
    product_id,
    price,
    user_id,
    source_table
FROM customers 
ORDER BY event_time 
LIMIT 5;

-- Final notification
DO $$
BEGIN
    RAISE NOTICE 'Exercise 02 completed successfully!';
END;
$$;
