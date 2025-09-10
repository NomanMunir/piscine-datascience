-- Exercise 02: Remove duplicates from customers table
-- Run this AFTER ex01_customers_table.sql
-- pgAdmin compatible version (no \echo commands)

-- Check if customers table exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'customers') THEN
        RAISE EXCEPTION '❌ customers table not found! Please run ex01_customers_table.sql first';
    END IF;
    RAISE NOTICE '✅ customers table found, proceeding with duplicate removal';
END;
$$;

-- Show current row count before deduplication
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

-- Show sample duplicate rows
WITH ranked_duplicates AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY user_id, product_id, price, event_type, DATE_TRUNC('second', event_time)
               ORDER BY event_time
           ) as row_num
    FROM customers
)
SELECT 
    'Sample duplicates to be removed:' as info,
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

-- Create backup table before removing duplicates
DROP TABLE IF EXISTS customers_backup;
CREATE TABLE customers_backup AS SELECT * FROM customers;

-- Notification that backup was created
DO $$
DECLARE
    backup_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO backup_count FROM customers_backup;
    RAISE NOTICE '💾 Backup created: customers_backup table with % rows', backup_count;
END;
$$;

-- Remove duplicates using ROW_NUMBER() window function
-- Keep the earliest occurrence of each duplicate group
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

-- Show deduplication results
SELECT 
    (SELECT COUNT(*) FROM customers_backup) as rows_before,
    (SELECT COUNT(*) FROM customers) as rows_after,
    (SELECT COUNT(*) FROM customers_backup) - (SELECT COUNT(*) FROM customers) as rows_removed;

-- Verify no duplicates remain
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
CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_unique_transaction 
ON customers (user_id, product_id, price, event_type, date_trunc('second', event_time));

-- Show sample of cleaned data
SELECT 
    'Sample cleaned data:' as info,
    event_time,
    event_type,
    product_id,
    price,
    user_id,
    source_table
FROM customers 
ORDER BY event_time 
LIMIT 10;

-- Final summary
DO $$
DECLARE
    final_count INTEGER;
    removed_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO final_count FROM customers;
    SELECT COUNT(*) INTO removed_count FROM customers_backup;
    removed_count := removed_count - final_count;
    
    RAISE NOTICE '';
    RAISE NOTICE '✅ Exercise 02 completed successfully!';
    RAISE NOTICE '📋 Summary:';
    RAISE NOTICE '   ✅ Identified and removed % duplicate rows', removed_count;
    RAISE NOTICE '   ✅ Kept earliest occurrence of each duplicate group';
    RAISE NOTICE '   ✅ Created backup table (customers_backup)';
    RAISE NOTICE '   ✅ Added unique constraint to prevent future duplicates';
    RAISE NOTICE '   📊 Final customers table has % rows', final_count;
END;
$$;
