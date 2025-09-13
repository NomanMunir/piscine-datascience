DO $$ BEGIN
    RAISE NOTICE 'Creating table structure...';
END $$;

CREATE TABLE IF NOT EXISTS data_2022_oct (
    event_time TIMESTAMP WITH TIME ZONE NOT NULL,  -- 1. TIMESTAMP WITH TIME ZONE (DateTime - first column)
    event_type VARCHAR(50) NOT NULL,               -- 2. VARCHAR (Text data type)
    product_id BIGINT NOT NULL,                     -- 3. BIGINT (Large integer)
    price NUMERIC(10,2) NOT NULL,                   -- 4. NUMERIC (Decimal with precision)
    user_id INTEGER NOT NULL,                       -- 5. INTEGER (Different from BIGINT)
    user_session UUID                               -- 6. UUID (UUID data type)
);

DO $$ BEGIN
    RAISE NOTICE 'Creating indexes for better performance...';
END $$;

CREATE INDEX IF NOT EXISTS idx_data_2022_oct_event_time ON data_2022_oct(event_time);
CREATE INDEX IF NOT EXISTS idx_data_2022_oct_user_id ON data_2022_oct(user_id);
CREATE INDEX IF NOT EXISTS idx_data_2022_oct_product_id ON data_2022_oct(product_id);

-- Check if table already has data before loading
DO $$ 
DECLARE
    row_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO row_count FROM data_2022_oct;
    
    IF row_count > 0 THEN
        RAISE NOTICE 'Table data_2022_oct already contains % rows. Skipping data loading.', row_count;
    ELSE
        RAISE NOTICE 'Loading data from CSV file (this may take a few minutes)...';
        
        -- Load data from CSV file
        COPY data_2022_oct(event_time, event_type, product_id, price, user_id, user_session)
        FROM '/app/data/customer/data_2022_oct.csv'
        WITH CSV HEADER DELIMITER ',';
        
        RAISE NOTICE 'Data loading completed! Checking row count...';
    END IF;
END $$;

SELECT COUNT(*) as total_rows FROM data_2022_oct;
