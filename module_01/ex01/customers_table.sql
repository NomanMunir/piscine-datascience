-- Exercise 01: Join all data_202* tables into a customers table
-- Run this after creating individual data tables from CSV files

\echo '🚀 Exercise 01: Creating customers table by joining all data_202* tables'

-- First, create all data tables from CSV files
\echo '📊 Step 1: Creating data tables from CSV files...'

-- Create automatic table function if not exists
CREATE OR REPLACE FUNCTION create_table_from_csv(table_name TEXT, csv_file_path TEXT)
RETURNS TEXT AS $$
DECLARE
    sql_command TEXT;
    result_message TEXT;
BEGIN
    sql_command := format('
        CREATE TABLE IF NOT EXISTS %I (
            event_time TIMESTAMP WITH TIME ZONE NOT NULL,
            event_type VARCHAR(50) NOT NULL,
            product_id BIGINT NOT NULL,
            price NUMERIC(10,2) NOT NULL,
            user_id BIGINT NOT NULL,
            user_session UUID
        )', table_name);
    
    EXECUTE sql_command;
    
    -- Add indexes
    EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%I_event_time ON %I(event_time)', table_name, table_name);
    EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%I_user_id ON %I(user_id)', table_name, table_name);
    EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%I_product_id ON %I(product_id)', table_name, table_name);
    
    -- Load data from CSV
    sql_command := format('
        COPY %I(event_time, event_type, product_id, price, user_id, user_session)
        FROM %L
        DELIMITER '',''
        CSV HEADER', table_name, csv_file_path);
    
    EXECUTE sql_command;
    
    EXECUTE format('SELECT COUNT(*) FROM %I', table_name) INTO result_message;
    RETURN format('✅ Table %I created with %s rows', table_name, result_message);
    
EXCEPTION WHEN OTHERS THEN
    RETURN format('❌ Error creating table %I: %s', table_name, SQLERRM);
END;
$$ LANGUAGE plpgsql;

-- Create tables from CSV files
SELECT create_table_from_csv('data_2022_oct', '/data/customer/data_2022_oct.csv');
SELECT create_table_from_csv('data_2022_nov', '/data/customer/data_2022_nov.csv');
SELECT create_table_from_csv('data_2022_dec', '/data/customer/data_2022_dec.csv');
SELECT create_table_from_csv('data_2023_jan', '/data/customer/data_2023_jan.csv');

\echo '📊 Step 2: Creating unified customers table...'

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
    source_table VARCHAR(50)  -- Track which original table the data came from
);

-- Join all data tables into customers table
DO $$
DECLARE
    table_record RECORD;
    sql_command TEXT;
    rows_inserted INTEGER;
    total_rows INTEGER := 0;
BEGIN
    RAISE NOTICE '🔄 Joining data from all tables...';
    
    FOR table_record IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' AND tablename LIKE 'data_202%'
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
        
        RAISE NOTICE '  ✅ Joined %: % rows added', table_record.tablename, rows_inserted;
    END LOOP;
    
    RAISE NOTICE '🎉 Total rows in customers table: %', total_rows;
END;
$$;

-- Create indexes for customers table
CREATE INDEX idx_customers_event_time ON customers(event_time);
CREATE INDEX idx_customers_user_id ON customers(user_id);
CREATE INDEX idx_customers_product_id ON customers(product_id);
CREATE INDEX idx_customers_source_table ON customers(source_table);

-- Show results
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT source_table) as number_of_source_tables,
    MIN(event_time) as earliest_event,
    MAX(event_time) as latest_event
FROM customers;

-- Show breakdown by source table
SELECT 
    source_table,
    COUNT(*) as row_count,
    MIN(event_time) as earliest_event,
    MAX(event_time) as latest_event
FROM customers 
GROUP BY source_table 
ORDER BY source_table;

\echo '✅ Exercise 01 completed successfully!'
\echo '📋 All data_202* tables have been joined into customers table'
