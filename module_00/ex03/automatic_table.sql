-- Function to create table and load data for a specific CSV file
CREATE OR REPLACE FUNCTION create_table_from_csv(table_name TEXT, csv_file_path TEXT)
RETURNS TEXT AS $$
DECLARE
    sql_command TEXT;
    result_message TEXT;
BEGIN
    -- Create the table with 6 DIFFERENT data types
    sql_command := format('
        CREATE TABLE IF NOT EXISTS %I (
            event_time TIMESTAMP WITH TIME ZONE NOT NULL,  -- 1. TIMESTAMP WITH TIME ZONE
            event_type VARCHAR(50) NOT NULL,               -- 2. VARCHAR
            product_id BIGINT NOT NULL,                     -- 3. BIGINT
            price NUMERIC(10,2) NOT NULL,                   -- 4. NUMERIC
            user_id INTEGER NOT NULL,                       -- 5. INTEGER (changed from BIGINT!)
            user_session UUID                               -- 6. UUID
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
