-- Create items table with at least 3 different data types
CREATE TABLE IF NOT EXISTS items (
    product_id BIGINT,
    category_id BIGINT,
    category_code VARCHAR(255),
    brand TEXT
);

-- Load data from CSV file with progress notification
DO $$
DECLARE
    row_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO row_count FROM items;
    
    IF row_count > 0 THEN
        RAISE NOTICE 'Items table already contains % rows. Skipping data load.', row_count;
    ELSE
        RAISE NOTICE 'Loading data from item.csv...';
        
        COPY items (product_id, category_id, category_code, brand)
        FROM '/data/data/item/item.csv'
        DELIMITER ','
        CSV HEADER;
        
        SELECT COUNT(*) INTO row_count FROM items;
        RAISE NOTICE 'Successfully loaded % rows into items table.', row_count;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error loading data: %', SQLERRM;
        RAISE;
END $$;
