-- Exercise 02: Create table for data_2022_oct.csv
-- Table name: data_2022_oct (without file extension)
-- Using at least 6 different PostgreSQL data types
-- DATETIME column as first column (mandatory)

-- Create the table with appropriate data types
CREATE TABLE IF NOT EXISTS data_2022_oct (
    event_time TIMESTAMP WITH TIME ZONE NOT NULL,  -- DateTime as first column (mandatory)
    event_type VARCHAR(50) NOT NULL,               -- Text data type
    product_id BIGINT NOT NULL,                     -- Large integer
    price NUMERIC(10,2) NOT NULL,                   -- Decimal with precision
    user_id BIGINT NOT NULL,                        -- Large integer 
    user_session UUID                               -- UUID data type (nullable for empty values)
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_data_2022_oct_event_time ON data_2022_oct(event_time);
CREATE INDEX IF NOT EXISTS idx_data_2022_oct_user_id ON data_2022_oct(user_id);
CREATE INDEX IF NOT EXISTS idx_data_2022_oct_product_id ON data_2022_oct(product_id);

-- Load data from CSV file
COPY data_2022_oct(event_time, event_type, product_id, price, user_id, user_session)
FROM '/data/customer/data_2022_oct.csv'
DELIMITER ','
CSV HEADER;

-- Display table structure
\d data_2022_oct;

-- Verify the data was loaded
SELECT COUNT(*) as total_rows FROM data_2022_oct;

-- Show sample data
SELECT * FROM data_2022_oct LIMIT 5;

-- Show data types used (for verification)
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    numeric_precision,
    numeric_scale,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'data_2022_oct'
ORDER BY ordinal_position;
