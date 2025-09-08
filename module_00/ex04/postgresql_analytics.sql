-- PostgreSQL Native Visualization and Analytics Extensions
-- Run these in your PostgreSQL database for enhanced analytics

-- 1. Enable PostGIS for spatial data (if needed)
-- CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. Enable pg_stat_statements for query performance monitoring
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- 3. Enable tablefunc for crosstab/pivot functionality
CREATE EXTENSION IF NOT EXISTS tablefunc;

-- 4. PIVOT TABLE Example - Brand vs Category Analysis
SELECT * FROM crosstab(
  'SELECT 
     COALESCE(brand, ''Unknown'') as brand,
     CASE 
       WHEN category_id IS NULL THEN ''No Category''
       ELSE category_id::text
     END as category,
     COUNT(*)::text
   FROM items 
   WHERE brand IS NOT NULL 
   GROUP BY brand, category_id 
   ORDER BY 1,2',
  'VALUES (''No Category''), (''1487580005268456192''), (''1487580005411062528''), (''1487580009471148032'')'
) AS ct(brand text, no_category text, cat1 text, cat2 text, cat3 text);

-- 5. Statistical Functions for Data Analysis
SELECT 
    'Items Statistics' as metric,
    COUNT(*) as total_items,
    COUNT(DISTINCT category_id) as unique_categories,
    COUNT(DISTINCT brand) as unique_brands,
    ROUND(AVG(LENGTH(COALESCE(brand, ''))), 2) as avg_brand_length,
    MIN(product_id) as min_product_id,
    MAX(product_id) as max_product_id,
    ROUND(STDDEV(product_id), 2) as product_id_stddev
FROM items;

-- 6. Percentile Analysis
SELECT 
    'Product ID Distribution' as analysis,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY product_id) as q1,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY product_id) as median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY product_id) as q3,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY product_id) as p95
FROM items;
