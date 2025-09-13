#!/bin/bash

if [ -f "../.env" ]; then
    source ../.env
fi

check_existing_data() {
    local existing_rows=$(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM customers;" 2>/dev/null | tr -d ' ')
    
    if [ "$existing_rows" -gt 0 ] 2>/dev/null; then
        echo "Customers table already contains $existing_rows rows. Skipping data load."
        return 0
    else
        return 1
    fi
}

create_indexes() {
    echo "Creating performance indexes..."
    
    docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" << 'EOF'
CREATE INDEX IF NOT EXISTS idx_customers_user_product_time ON customers (user_id, product_id, event_time);
CREATE INDEX IF NOT EXISTS idx_customers_dedup_columns ON customers (user_id, product_id, event_type, price, user_session);
CREATE INDEX IF NOT EXISTS idx_customers_event_time ON customers (event_time);
CREATE INDEX IF NOT EXISTS idx_customers_user_session ON customers (user_session);
CREATE INDEX IF NOT EXISTS idx_customers_composite_lookup ON customers (event_type, product_id, user_id);
EOF

    if [ $? -ne 0 ]; then
        echo "✗ Failed to create indexes"
        return 1
    fi
    
    echo "✓ Successfully created all indexes"
    return 0
}

find_source_tables() {
    local tables=($(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' AND tablename LIKE 'data_202%'
        ORDER BY tablename;
    " | tr -d ' '))
    
    if [ ${#tables[@]} -eq 0 ]; then
        echo "✗ No data_202* tables found!" >&2
        return 1
    fi
    
    echo "Found ${#tables[@]} tables: ${tables[*]}" >&2
    echo "${tables[@]}"
    return 0
}

create_customers_from_union() {
    local tables=("$@")  # Receive all arguments as array
    
    if [ ${#tables[@]} -eq 0 ]; then
        echo "✗ No tables to union"
        return 1
    fi
    
    echo "Creating customers table from ${#tables[@]} tables using UNION ALL..."
    
    local union_query=""
    for i in "${!tables[@]}"; do
        if [ $i -eq 0 ]; then
            union_query="SELECT event_time, event_type, product_id, price, user_id, user_session FROM ${tables[$i]}"
        else
            union_query="$union_query UNION ALL SELECT event_time, event_type, product_id, price, user_id, user_session FROM ${tables[$i]}"
        fi
    done
    
    docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" << EOF
CREATE TABLE customers AS
$union_query;
EOF

    if [ $? -eq 0 ]; then
        echo "✓ Successfully created customers table from all tables"
        return 0
    else
        echo "✗ Failed to create customers table"
        return 1
    fi
}

echo "Creating customers table from all data_202* tables..."

if check_existing_data; then
    exit 0
fi

source_tables=$(find_source_tables)
if [ $? -ne 0 ]; then
    exit 1
fi

tables=($source_tables)
total_tables=${#tables[@]}

echo "Processing $total_tables tables..."

if ! create_customers_from_union "${tables[@]}"; then
    exit 1
fi

if ! create_indexes; then
    exit 1
fi

final_count=$(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM customers;" | tr -d ' ')

echo ""
echo "✓ Successfully created customers table!"
echo "✓ Total rows inserted: $final_count"
echo "✓ Tables processed: $total_tables"