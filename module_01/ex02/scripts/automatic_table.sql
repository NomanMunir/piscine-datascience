-- Exercise 03: Truly Automatic table creation for all CSV files
-- This script dynamically creates tables for ANY CSV files found in the customer folder
-- No need to manually list filenames!

-- Function to create table and load data for a specific CSV file
CREATE OR REPLACE FUNCTION create_table_from_csv(table_name TEXT, csv_file_path TEXT)
RETURNS TEXT AS $$
DECLARE
    sql_command TEXT;
    result_message TEXT;
BEGIN
    -- Create the table with the same structure as our previous table
    -- Using the same 6 data types as required
    sql_command := format('
        CREATE TABLE IF NOT EXISTS %I (
            event_time TIMESTAMP WITH TIME ZONE NOT NULL,  -- DateTime as first column (mandatory)
            event_type VARCHAR(50) NOT NULL,               -- Text data type
            product_id BIGINT NOT NULL,                     -- Large integer
            price NUMERIC(10,2) NOT NULL,                   -- Decimal with precision
            user_id BIGINT NOT NULL,                        -- Large integer 
            user_session UUID                               -- UUID data type (nullable for empty values)
        )', table_name);
    
    EXECUTE sql_command;
    
    -- Add indexes for better performance
    EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%I_event_time ON %I(event_time)', table_name, table_name);
    EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%I_user_id ON %I(user_id)', table_name, table_name);
    EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%I_product_id ON %I(product_id)', table_name, table_name);
    
    -- Load data from CSV file
    sql_command := format('
        COPY %I(event_time, event_type, product_id, price, user_id, user_session)
        FROM %L
        DELIMITER '',''
        CSV HEADER', table_name, csv_file_path);
    
    EXECUTE sql_command;
    
    -- Get row count for verification
    EXECUTE format('SELECT COUNT(*) FROM %I', table_name) INTO result_message;
    
    RETURN format('✅ Table %I created successfully with %s rows', table_name, result_message);
    
EXCEPTION WHEN OTHERS THEN
    RETURN format('❌ Error creating table %I: %s', table_name, SQLERRM);
END;
$$ LANGUAGE plpgsql;

-- This function will be called by the shell script with dynamic file list
-- No hardcoded filenames here!

-- Display summary of all created tables
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count,
    pg_size_pretty(pg_total_relation_size(table_name::regclass)) as table_size
FROM information_schema.tables t
WHERE table_schema = 'public' 
AND table_name LIKE 'data_202%'
ORDER BY table_name;

-- Show data types for verification (should be 6 different types for each table)
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name LIKE 'data_202%'
AND table_schema = 'public'
ORDER BY table_name, ordinal_position;
