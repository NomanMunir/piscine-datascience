-- Exercise 04: Items table creation
-- Creates a table named 'items' using column names from item.csv
-- Contains three different PostgreSQL data types: BIGINT, VARCHAR, TEXT

-- Create the items table with appropriate data types
CREATE TABLE IF NOT EXISTS items (
    product_id BIGINT NOT NULL,           -- Large integer type for product IDs
    category_id BIGINT NOT NULL,          -- Large integer type for category IDs  
    category_code VARCHAR(255),           -- Variable character type for category codes (can be NULL)
    brand TEXT                            -- Text type for brand names (can be NULL, unlimited length)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_items_product_id ON items(product_id);
CREATE INDEX IF NOT EXISTS idx_items_category_id ON items(category_id);
CREATE INDEX IF NOT EXISTS idx_items_brand ON items(brand);

-- Load data from the item.csv file
COPY items(product_id, category_id, category_code, brand)
FROM '/data/item/item.csv'
DELIMITER ','
CSV HEADER;

-- Display success message and row count
DO $$
DECLARE
    row_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO row_count FROM items;
    RAISE NOTICE '✅ Items table created successfully with % rows', row_count;
    RAISE NOTICE '📊 Table contains three data types: BIGINT, VARCHAR(255), TEXT';
END $$;
