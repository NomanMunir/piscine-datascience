-- Exercise 01: Join all data_202* tables into a customers table
-- This script combines all monthly customer data into a single unified table

\echo '🚀 Starting Exercise 01: Creating customers table by joining all data_202* tables'

-- Check if we have any data tables available
DO $$
DECLARE
    table_record RECORD;
    table_count INTEGER := 0;
BEGIN
    RAISE NOTICE '📋 Checking for available data_202* tables...';
    FOR table_record IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' AND tablename LIKE 'data_202%'
        ORDER BY tablename
    LOOP
        table_count := table_count + 1;
        RAISE NOTICE '  ✅ Found table: %', table_record.tablename;
    END LOOP;
    
    IF table_count = 0 THEN
        RAISE EXCEPTION '❌ No data_202* tables found! Please run Module 00 exercises first to create the source tables.';
    END IF;
    
    RAISE NOTICE '📊 Total data tables found: %', table_count;
END;
$$;

-- Drop existing customers table if it exists
DROP TABLE IF EXISTS customers CASCADE;

\echo '🏗️  Creating customers table structure...'

-- Create the unified customers table with the same structure as the source tables
CREATE TABLE customers (
    event_time TIMESTAMP,
    event_type VARCHAR(50),
    product_id BIGINT,
    price DECIMAL(10,2),
    user_id BIGINT,
    user_session UUID,
    source_table VARCHAR(50)  -- Track which original table the data came from
);

\echo '📋 Creating indexes for better performance...'

-- Create indexes for better query performance
CREATE INDEX idx_customers_event_time ON customers(event_time);
CREATE INDEX idx_customers_user_id ON customers(user_id);
CREATE INDEX idx_customers_product_id ON customers(product_id);
CREATE INDEX idx_customers_event_type ON customers(event_type);
CREATE INDEX idx_customers_source_table ON customers(source_table);

\echo '🔄 Joining data from all tables...'

-- Dynamic insertion from all data_202* tables
DO $$
DECLARE
    table_record RECORD;
    sql_command TEXT;
    rows_inserted INTEGER;
    total_rows INTEGER := 0;
BEGIN
    RAISE NOTICE '🔄 Starting to join data from all tables...';
    
    FOR table_record IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' AND tablename LIKE 'data_202%'
        ORDER BY tablename
    LOOP
        -- Build dynamic SQL to insert data from each table
        sql_command := format('
            INSERT INTO customers (event_time, event_type, product_id, price, user_id, user_session, source_table)
            SELECT 
                event_time, 
                event_type, 
                product_id, 
                price, 
                user_id, 
                user_session,
                %L as source_table
            FROM %I',
            table_record.tablename,
            table_record.tablename
        );
        
        -- Execute the insert
        EXECUTE sql_command;
        
        -- Get the number of rows inserted
        GET DIAGNOSTICS rows_inserted = ROW_COUNT;
        total_rows := total_rows + rows_inserted;
        
        RAISE NOTICE '  ✅ Joined %: % rows added', table_record.tablename, rows_inserted;
    END LOOP;
    
    RAISE NOTICE '🎉 Successfully joined all tables! Total rows in customers table: %', total_rows;
END;
$$;

\echo '📊 Analyzing the joined data...'

-- Display summary statistics
SELECT 
    'customers' as table_name,
    COUNT(*) as total_rows,
    COUNT(DISTINCT source_table) as number_of_source_tables,
    MIN(event_time) as earliest_event,
    MAX(event_time) as latest_event,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT product_id) as unique_products
FROM customers;

\echo '📈 Breakdown by source table:'

-- Show breakdown by source table
SELECT 
    source_table,
    COUNT(*) as row_count,
    MIN(event_time) as earliest_event,
    MAX(event_time) as latest_event,
    COUNT(DISTINCT user_id) as unique_users
FROM customers 
GROUP BY source_table 
ORDER BY source_table;

\echo '🔍 Sample data from customers table:'

-- Show sample data
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

\echo '✅ Exercise 01 completed successfully!'
\echo '📋 Summary: All data_202* tables have been joined into a single customers table'
\echo '🎯 The customers table now contains all customer transaction data from different time periods'
