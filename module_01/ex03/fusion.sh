#!/bin/bash

if [ -f "../.env" ]; then
    source ../.env
fi

check_required_tables() {
    local customers_exists=$(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "
        SELECT COUNT(*) FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'customers';
    " 2>/dev/null | tr -d ' ')
    
    local items_exists=$(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "
        SELECT COUNT(*) FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'items';
    " 2>/dev/null | tr -d ' ')
    
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
    local count=$(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM $table_name;" 2>/dev/null | tr -d ' ')
    echo "$count"
}

check_existing_fusion() {
    local existing_rows=$(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "
        SELECT COUNT(*) FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'customers_items';
    " 2>/dev/null | tr -d ' ')
    
    if [ "$existing_rows" -eq 1 ] 2>/dev/null; then
        local row_count=$(get_row_count "customers_items")
        if [ "$row_count" -gt 0 ] 2>/dev/null; then
            echo "Fusion table 'customers_items' already exists with $row_count rows. Skipping creation."
            return 0
        fi
    fi
    
    return 1
}

create_fusion_table() {
    echo "Creating fusion table by joining customers with items..."
    
    docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" << 'EOF'
DROP TABLE IF EXISTS customers_items;

CREATE TABLE customers_items AS
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
LEFT JOIN items i ON c.product_id = i.product_id
ORDER BY c.event_time;
EOF

    if [ $? -ne 0 ]; then
        echo "✗ Failed to create fusion table"
        return 1
    fi
    
    return 0
}

create_fusion_indexes() {
    echo "Creating performance indexes for fusion table..."
    
    docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" << 'EOF'
CREATE INDEX IF NOT EXISTS idx_customers_items_event_time ON customers_items (event_time);
CREATE INDEX IF NOT EXISTS idx_customers_items_user_id ON customers_items (user_id);
CREATE INDEX IF NOT EXISTS idx_customers_items_product_id ON customers_items (product_id);
CREATE INDEX IF NOT EXISTS idx_customers_items_category_id ON customers_items (category_id);
CREATE INDEX IF NOT EXISTS idx_customers_items_user_session ON customers_items (user_session);
CREATE INDEX IF NOT EXISTS idx_customers_items_composite ON customers_items (user_id, product_id, event_time);
EOF

    if [ $? -ne 0 ]; then
        echo "✗ Failed to create fusion table indexes"
        return 1
    fi
    
    echo "✓ Successfully created all fusion table indexes"
    return 0
}

echo "Creating fusion of customers and items tables..."

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

if ! create_fusion_table; then
    exit 1
fi

if ! create_fusion_indexes; then
    exit 1
fi

fusion_count=$(get_row_count "customers_items")

echo ""
echo "✓ Successfully created fusion table!"
echo "✓ Customers rows: $customers_count"
echo "✓ Items rows: $items_count"
echo "✓ Fusion rows: $fusion_count"
echo "✓ Table: customers_items"