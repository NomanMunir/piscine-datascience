#!/bin/bash

if [ -f "../.env" ]; then
    source ../.env
fi

check_customers_exists() {
    local table_exists=$(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "
        SELECT COUNT(*) FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'customers';
    " 2>/dev/null | tr -d ' ')
    
    if [ "$table_exists" -ne 1 ] 2>/dev/null; then
        echo "✗ Customers table does not exist!"
        return 1
    fi
    
    return 0
}

get_row_count() {
    local table_name=$1
    local count=$(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM $table_name;" 2>/dev/null | tr -d ' ')
    echo "$count"
}

create_dedup_table() {
    echo "Creating deduplicated table using DISTINCT ON..."
    
    docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" << 'EOF'
DROP TABLE IF EXISTS customers_dedup;

CREATE TABLE customers_dedup AS
SELECT DISTINCT ON (event_type, product_id, user_id, user_session, date_trunc('second', event_time))
       *
FROM customers
ORDER BY event_type, product_id, user_id, user_session, date_trunc('second', event_time), event_time;
EOF

    if [ $? -ne 0 ]; then
        echo "✗ Failed to create deduplicated table"
        return 1
    fi
    
    return 0
}

replace_customers_table() {
    echo "Replacing original customers table with deduplicated data..."
    
    docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" << 'EOF'
DROP TABLE customers;
ALTER TABLE customers_dedup RENAME TO customers;
EOF

    if [ $? -ne 0 ]; then
        echo "✗ Failed to replace customers table"
        return 1
    fi
    
    return 0
}

recreate_indexes() {
    echo "Recreating performance indexes..."
    
    docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" << 'EOF'
CREATE INDEX IF NOT EXISTS idx_customers_user_product_time ON customers (user_id, product_id, event_time);
CREATE INDEX IF NOT EXISTS idx_customers_dedup_columns ON customers (user_id, product_id, event_type, price, user_session);
CREATE INDEX IF NOT EXISTS idx_customers_event_time ON customers (event_time);
CREATE INDEX IF NOT EXISTS idx_customers_user_session ON customers (user_session);
CREATE INDEX IF NOT EXISTS idx_customers_composite_lookup ON customers (event_type, product_id, user_id);
EOF

    if [ $? -ne 0 ]; then
        echo "✗ Failed to recreate indexes"
        return 1
    fi
    
    echo "✓ Successfully recreated all indexes"
    return 0
}

echo "Removing duplicates from customers table using DISTINCT ON method..."

if ! check_customers_exists; then
    exit 1
fi

original_count=$(get_row_count "customers")
echo "Original rows: $original_count"

if [ "$original_count" -eq 0 ]; then
    echo "Table is empty. Nothing to remove."
    exit 0
fi

if ! create_dedup_table; then
    exit 1
fi

dedup_count=$(get_row_count "customers_dedup")
echo "Deduplicated rows: $dedup_count"

if ! replace_customers_table; then
    exit 1
fi

if ! recreate_indexes; then
    exit 1
fi

final_count=$(get_row_count "customers")
removed=$((original_count - final_count))

echo ""
echo "✓ Successfully cleaned customers table!"
echo "✓ Original rows: $original_count"
echo "✓ Final rows: $final_count"
echo "✓ Removed: $removed duplicates"