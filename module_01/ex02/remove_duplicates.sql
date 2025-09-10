-- Exercise 02: Remove duplicates from customers table
-- Run this AFTER ex01_customers_table.sql

\echo '🚀 Exercise 02: Removing duplicate rows from customers table'

-- Check if customers table exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'customers') THEN
        RAISE EXCEPTION '❌ customers table not found! Please run ex01_customers_table.sql first';
    END IF;
END;
$$;

-- Analyze current duplicate patterns
\echo '🔍 Analyzing duplicate patterns...'

-- Show current row count
SELECT 
    'Before deduplication' as status,
    COUNT(*) as total_rows
FROM customers;

-- Identify potential duplicates (same user, product, price, event_type within 1 second)
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

-- Show sample duplicates
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
    source_table
FROM ranked_duplicates 
WHERE row_num > 1
ORDER BY user_id, product_id, event_time
LIMIT 10;

\echo '💾 Creating backup table...'

-- Create backup table
DROP TABLE IF EXISTS customers_backup;
CREATE TABLE customers_backup AS SELECT * FROM customers;

\echo '🧹 Removing duplicates...'

-- Remove duplicates using ROW_NUMBER() window function
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
WHERE (event_time, event_type, product_id, price, user_id, user_session, source_table) IN (
    SELECT event_time, event_type, product_id, price, user_id, user_session, source_table
    FROM duplicates_to_remove
);

-- Show results
\echo '📈 Deduplication results:'

SELECT 
    (SELECT COUNT(*) FROM customers_backup) as rows_before,
    (SELECT COUNT(*) FROM customers) as rows_after,
    (SELECT COUNT(*) FROM customers_backup) - (SELECT COUNT(*) FROM customers) as rows_removed;

-- Verify no duplicates remain
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

-- Create unique constraint to prevent future duplicates
\echo '🔧 Adding unique constraint...'
CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_unique_transaction 
ON customers (user_id, product_id, price, event_type, date_trunc('second', event_time));

-- Show sample of cleaned data
\echo '📋 Sample of cleaned data:'
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

\echo '✅ Exercise 02 completed successfully!'
\echo '📋 Summary:'
\echo '   ✅ Identified and removed duplicate rows'
\echo '   ✅ Kept earliest occurrence of each duplicate group'
\echo '   ✅ Created backup table (customers_backup)'
\echo '   ✅ Added unique constraint to prevent future duplicates'
