-- Master Initialization Script for Piscine Data Science
-- This script initializes all tables and functions needed for the exercises

\echo '🚀 Starting Piscine Data Science Database Initialization'
\echo '=================================================='

-- Step 1: Create the automatic table function
\echo '📋 Step 1: Setting up automatic table creation function...'
\i /scripts/automatic_table.sql

-- Step 2: Create all data tables from CSV files
\echo '📊 Step 2: Creating data tables from CSV files...'

-- Create data tables using the function
SELECT create_table_from_csv('data_2022_oct', '/data/customer/data_2022_oct.csv');
SELECT create_table_from_csv('data_2022_nov', '/data/customer/data_2022_nov.csv');
SELECT create_table_from_csv('data_2022_dec', '/data/customer/data_2022_dec.csv');
SELECT create_table_from_csv('data_2023_jan', '/data/customer/data_2023_jan.csv');

-- Step 3: Create items table
\echo '🛍️  Step 3: Creating items table...'
\i /scripts/items_table.sql

-- Step 4: Show summary of all created tables
\echo '📈 Step 4: Database initialization summary...'

-- Show all created data tables
SELECT 
    'Data Tables' as table_type,
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name AND table_schema = 'public') as columns,
    pg_size_pretty(pg_total_relation_size(table_name::regclass)) as size
FROM information_schema.tables t
WHERE table_schema = 'public' 
AND table_name LIKE 'data_202%'
ORDER BY table_name;

-- Show items table info
SELECT 
    'Items Table' as table_type,
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name AND table_schema = 'public') as columns,
    pg_size_pretty(pg_total_relation_size(table_name::regclass)) as size
FROM information_schema.tables t
WHERE table_schema = 'public' 
AND table_name = 'items';

-- Show total row counts
SELECT 
    'data_2022_oct' as table_name,
    (SELECT COUNT(*) FROM data_2022_oct) as row_count
UNION ALL
SELECT 
    'data_2022_nov' as table_name,
    (SELECT COUNT(*) FROM data_2022_nov) as row_count
UNION ALL
SELECT 
    'data_2022_dec' as table_name,
    (SELECT COUNT(*) FROM data_2022_dec) as row_count
UNION ALL
SELECT 
    'data_2023_jan' as table_name,
    (SELECT COUNT(*) FROM data_2023_jan) as row_count
UNION ALL
SELECT 
    'items' as table_name,
    (SELECT COUNT(*) FROM items) as row_count
ORDER BY table_name;

\echo ''
\echo '✅ Database initialization completed successfully!'
\echo '📋 Summary:'
\echo '   ✅ Automatic table function created'
\echo '   ✅ 4 customer data tables created (data_202*)'
\echo '   ✅ Items table created'
\echo '   ✅ All indexes created for performance'
\echo ''
\echo '🎯 Next steps:'
\echo '   • Run ex01_customers_table.sql to create unified customers table'
\echo '   • Run ex02_remove_duplicates.sql to clean duplicate data'
\echo ''
\echo '🌐 Access pgAdmin at http://localhost:8080'
\echo '📝 Credentials: admin@piscineds.com / admin123'
