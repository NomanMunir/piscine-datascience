-- Exercise 01: Join all data_20* tables into a customers table (pgAdmin compatible)

-- Check if we have data tables available
DO $$
DECLARE
    table_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO table_count
    FROM pg_tables 
    WHERE schemaname = 'public' AND tablename LIKE 'data_20%';
    
    IF table_count = 0 THEN
        RAISE EXCEPTION 'No data_20* tables found! Please run init.sql first.';
    END IF;
    
    RAISE NOTICE 'Found % data_20* tables to join', table_count;
END;
$$;

-- Drop existing customers table if it exists
DROP TABLE IF EXISTS customers CASCADE;

-- Create the unified customers table
CREATE TABLE customers (
    event_time TIMESTAMP WITH TIME ZONE,
    event_type VARCHAR(50),
    product_id BIGINT,
    price NUMERIC(10,2),
    user_id BIGINT,
    user_session UUID,
    source_table VARCHAR(50)
);

-- Join all data_20* tables into customers table
DO $$
DECLARE
    table_record RECORD;
    sql_command TEXT;
    rows_inserted INTEGER;
    total_rows INTEGER := 0;
BEGIN
    RAISE NOTICE 'Starting to join data from all data_20* tables...';
    
    FOR table_record IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' AND tablename LIKE 'data_20%'
        ORDER BY tablename
    LOOP
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
        
        EXECUTE sql_command;
        GET DIAGNOSTICS rows_inserted = ROW_COUNT;
        total_rows := total_rows + rows_inserted;
        
        RAISE NOTICE 'Joined %: % rows added', table_record.tablename, rows_inserted;
    END LOOP;
    
    RAISE NOTICE 'Successfully joined all tables! Total rows: %', total_rows;
END;
$$;

-- Create indexes
CREATE INDEX idx_customers_event_time ON customers(event_time);
CREATE INDEX idx_customers_user_id ON customers(user_id);
CREATE INDEX idx_customers_product_id ON customers(product_id);
CREATE INDEX idx_customers_event_type ON customers(event_type);
CREATE INDEX idx_customers_source_table ON customers(source_table);

-- Show results
SELECT 
    'customers' as table_name,
    COUNT(*) as total_rows,
    COUNT(DISTINCT source_table) as number_of_source_tables,
    MIN(event_time) as earliest_event,
    MAX(event_time) as latest_event,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT product_id) as unique_products
FROM customers;

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
