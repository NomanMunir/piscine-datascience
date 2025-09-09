-- Exercise 02: Remove duplicates from customers table
-- This script identifies and removes duplicate rows that occur due to rapid successive instructions

\echo '🚀 Starting Exercise 02: Removing duplicate rows from customers table'

-- First, let's analyze the current state of duplicates
\echo '🔍 Analyzing duplicate patterns in customers table...'

-- Show current row count
SELECT 
    'Before deduplication' as status,
    COUNT(*) as total_rows
FROM customers;

-- Identify potential duplicates (same user, product, price, event_type within 1 second)
\echo '📊 Identifying potential duplicate groups...'

WITH duplicate_analysis AS (
    SELECT 
        user_id,
        product_id,
        price,
        event_type,
        DATE_TRUNC('second', event_time) as event_second,
        COUNT(*) as duplicate_count,
        MIN(event_time) as first_occurrence,
        MAX(event_time) as last_occurrence
    FROM customers 
    GROUP BY user_id, product_id, price, event_type, DATE_TRUNC('second', event_time)
    HAVING COUNT(*) > 1
)
SELECT 
    COUNT(*) as duplicate_groups,
    SUM(duplicate_count) as total_duplicate_rows,
    SUM(duplicate_count - 1) as rows_to_remove
FROM duplicate_analysis;

-- Show some examples of duplicates
\echo '🔍 Sample duplicate rows:'
WITH ranked_duplicates AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY user_id, product_id, price, event_type, DATE_TRUNC('second', event_time)
               ORDER BY event_time
           ) as row_num
    FROM customers
)
SELECT 
    event_time,
    event_type,
    product_id,
    price,
    user_id,
    user_session
FROM ranked_duplicates 
WHERE row_num > 1
ORDER BY user_id, product_id, event_time
LIMIT 10;

\echo '🧹 Starting deduplication process...'

-- Create a backup table first
DROP TABLE IF EXISTS customers_backup;
CREATE TABLE customers_backup AS SELECT * FROM customers;

\echo '💾 Backup created: customers_backup table'

-- Method 1: Use ROW_NUMBER() to identify and keep only the first occurrence of each duplicate group
-- We'll keep the earliest timestamp for each group of duplicates
WITH numbered_rows AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY 
                   user_id, 
                   product_id, 
                   price, 
                   event_type,
                   DATE_TRUNC('second', event_time)  -- Group by second to catch rapid duplicates
               ORDER BY event_time ASC  -- Keep the earliest occurrence
           ) as row_num
    FROM customers
),
duplicates_to_remove AS (
    SELECT *
    FROM numbered_rows
    WHERE row_num > 1
)
DELETE FROM customers 
WHERE (event_time, event_type, product_id, price, user_id, user_session) IN (
    SELECT event_time, event_type, product_id, price, user_id, user_session
    FROM duplicates_to_remove
);

-- Get count of removed rows
\echo '📈 Deduplication completed!'

-- Show the results
SELECT 
    'After deduplication' as status,
    COUNT(*) as total_rows
FROM customers;

-- Show the difference
SELECT 
    (SELECT COUNT(*) FROM customers_backup) as rows_before,
    (SELECT COUNT(*) FROM customers) as rows_after,
    (SELECT COUNT(*) FROM customers_backup) - (SELECT COUNT(*) FROM customers) as rows_removed;

-- Verify no duplicates remain (should return 0 rows)
\echo '✅ Verification: Checking for remaining duplicates...'
WITH remaining_duplicates AS (
    SELECT 
        user_id,
        product_id,
        price,
        event_type,
        DATE_TRUNC('second', event_time) as event_second,
        COUNT(*) as duplicate_count
    FROM customers 
    GROUP BY user_id, product_id, price, event_type, DATE_TRUNC('second', event_time)
    HAVING COUNT(*) > 1
)
SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ No duplicates remaining!'
        ELSE CONCAT('⚠️ ', COUNT(*), ' duplicate groups still found')
    END as verification_result
FROM remaining_duplicates;

-- Show sample of cleaned data
\echo '📋 Sample of cleaned customers data:'
SELECT 
    event_time,
    event_type,
    product_id,
    price,
    user_id,
    source_table
FROM customers 
ORDER BY event_time 
LIMIT 10;

-- Create index to prevent future duplicates (optional)
\echo '🔧 Creating composite index to prevent future duplicates...'
CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_unique_transaction 
ON customers (user_id, product_id, price, event_type, date_trunc('second', event_time));

\echo '✅ Exercise 02 completed successfully!'
\echo '📋 Summary:'
\echo '   ✅ Identified and removed duplicate rows'
\echo '   ✅ Kept earliest occurrence of each duplicate group'
\echo '   ✅ Created backup table for safety'
\echo '   ✅ Added unique constraint to prevent future duplicates'
