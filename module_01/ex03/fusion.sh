#!/bin/bash

if [ -f "../.env" ]; then
    source ../.env
fi

execute_sql() {
    local sql_query="$1"
    docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "$sql_query" 2>/dev/null | tr -d ' '
}

execute_sql_script() {
    docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"
}

check_required_tables() {
    local customers_exists=$(execute_sql "
        SELECT COUNT(*) FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'customers';
    ")
    
    local items_exists=$(execute_sql "
        SELECT COUNT(*) FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'items';
    ")
    
    if [ "$customers_exists" -ne 1 ] 2>/dev/null; then
        echo "✗ Customers table does not exist!"
        return 1
    fi
    
    if [ "$items_exists" -ne 1 ] 2>/dev/null; then
        echo "✗ Items table does not exist!"
        return 1
    fi
    
    return 0
}

get_row_count() {
    local table_name=$1
    local count=$(execute_sql "SELECT COUNT(*) FROM $table_name;")
    echo "$count"
}

check_existing_fusion() {
    local has_items_columns=$(execute_sql "
        SELECT COUNT(*) FROM information_schema.columns 
        WHERE table_name = 'customers' 
        AND column_name IN ('category_id', 'category_code', 'brand');
    ")
    
    if [ "$has_items_columns" -eq 3 ] 2>/dev/null; then
        echo "Customers table already has items columns. Skipping fusion."
        return 0
    fi
    
    return 1
}

create_clean_items_table() {
    echo "Creating clean items table (removing duplicates by keeping most complete records)..."
    
    execute_sql_script << 'EOF'
DROP TABLE IF EXISTS items_clean;

CREATE TABLE items_clean AS
SELECT DISTINCT ON (product_id) 
    product_id, 
    category_id, 
    category_code, 
    brand
FROM items
ORDER BY product_id, 
    (CASE WHEN brand IS NOT NULL AND brand != '' THEN 1 ELSE 0 END) DESC,
    (CASE WHEN category_code IS NOT NULL AND category_code != '' THEN 1 ELSE 0 END) DESC,
    (CASE WHEN category_id IS NOT NULL THEN 1 ELSE 0 END) DESC;
EOF

    if [ $? -ne 0 ]; then
        echo "✗ Failed to create clean items table"
        return 1
    fi
    
    return 0
}

create_fusion_table() {
    echo "Creating enhanced customers table with items information..."
    
    execute_sql_script << 'EOF'
-- Create enhanced customers table with items info
CREATE TABLE customers_tmp AS (
    SELECT 
        c.event_time,
        c.event_type,
        c.product_id,
        c.price,
        c.user_id,
        c.user_session,
        i.category_id,
        i.category_code,
        i.brand
    FROM customers c
    LEFT JOIN items_clean i ON c.product_id = i.product_id
);

-- Replace original customers table
DROP TABLE customers;
ALTER TABLE customers_tmp RENAME TO customers;
EOF

    if [ $? -ne 0 ]; then
        echo "✗ Failed to create enhanced customers table"
        return 1
    fi
    
    return 0
}

create_fusion_indexes() {
    echo "Creating performance indexes for enhanced customers table..."
    
    execute_sql_script << 'EOF'
CREATE INDEX IF NOT EXISTS idx_customers_category_id ON customers (category_id);
CREATE INDEX IF NOT EXISTS idx_customers_brand ON customers (brand);
CREATE INDEX IF NOT EXISTS idx_customers_category_code ON customers (category_code);
EOF

    if [ $? -ne 0 ]; then
        echo "✗ Failed to create fusion indexes"
        return 1
    fi
    
    echo "✓ Successfully created fusion indexes"
    return 0
}

echo "Adding items information to customers table..."

if ! check_required_tables; then
    exit 1
fi

if check_existing_fusion; then
    exit 0
fi

customers_count=$(get_row_count "customers")
items_count=$(get_row_count "items")
echo "Customers rows: $customers_count"
echo "Items rows: $items_count"

if ! create_clean_items_table; then
    exit 1
fi

items_clean_count=$(get_row_count "items_clean")
echo "Items (after deduplication): $items_clean_count"

if ! create_fusion_table; then
    exit 1
fi

if ! create_fusion_indexes; then
    exit 1
fi

final_customers_count=$(get_row_count "customers")

echo ""
echo "✓ Successfully enhanced customers table with items information!"
echo "✓ Customers rows: $final_customers_count (no data lost)"
echo "✓ Original items rows: $items_count"
echo "✓ Clean items rows: $items_clean_count"
echo "✓ Enhanced table: customers (with category_id, category_code, brand columns)"