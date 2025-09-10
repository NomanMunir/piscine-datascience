-- Exercise 02: Remove duplicates - SIMPLEST VERSION

-- Step 1: Add a unique constraint (this will fail if duplicates exist)
-- ALTER TABLE customers ADD CONSTRAINT customers_unique 
-- UNIQUE (user_id, product_id, event_type, price, DATE_TRUNC('second', event_time));

-- Step 2: If constraint fails, use this manual approach
-- First, let's see how many duplicates we actually have:
SELECT 
    user_id, product_id, event_type, price, DATE_TRUNC('second', event_time) as event_second,
    COUNT(*) as duplicate_count
FROM customers 
GROUP BY user_id, product_id, event_type, price, DATE_TRUNC('second', event_time)
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC
LIMIT 10;

-- Step 3: If there are many duplicates, create a new clean table
DROP TABLE IF EXISTS customers_new;
CREATE TABLE customers_new AS 
SELECT DISTINCT 
    event_time,
    event_type,
    product_id,
    price,
    user_id,
    user_session,
    source_table
FROM customers;

-- Step 4: Replace the table
DROP TABLE customers;
ALTER TABLE customers_new RENAME TO customers;

-- Final check
SELECT COUNT(*) as final_count FROM customers;
