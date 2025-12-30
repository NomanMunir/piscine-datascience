#!/bin/bash

if [ -f "../../.env" ]; then
    source ../../.env
fi



check_existing_data() {
    local existing_rows=$(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM items;" 2>/dev/null | tr -d ' ')
    
    if [ "$existing_rows" -gt 0 ] 2>/dev/null; then
        echo "Items table already contains $existing_rows rows. Skipping data load."
        return 0
    else
        return 1
    fi
}

# Function to create items table structure
create_items_table() {
    echo "Creating items table structure..."
    
    docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" << 'EOF'
CREATE TABLE IF NOT EXISTS items (
    product_id BIGINT,
    category_id BIGINT,
    category_code VARCHAR(255),
    brand TEXT
);

CREATE INDEX IF NOT EXISTS idx_items_product_id ON items(product_id);
CREATE INDEX IF NOT EXISTS idx_items_category_id ON items(category_id);
CREATE INDEX IF NOT EXISTS idx_items_brand ON items(brand);
EOF

    if [ $? -ne 0 ]; then
        echo "✗ Failed to create items table structure"
        return 1
    fi
    
    return 0
}

# Function to load items CSV data
load_items_data() {
    echo "Loading items CSV data..."
    
    docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" << EOF
COPY items (product_id, category_id, category_code, brand)
FROM '$CONTAINER_DATA_PATH/item/item.csv'
WITH CSV HEADER DELIMITER ',';
EOF

    if [ $? -eq 0 ]; then
        # Get final count
        local final_count=$(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM items;" | tr -d ' ')
        echo "✓ Successfully loaded $final_count rows into items table"
        return 0
    else
        echo "✗ Failed to load items data"
        return 1
    fi
}

echo "Creating items table..."

# Check if table already has data
if check_existing_data; then
    exit 0
fi

if ! create_items_table; then
    echo "✗ Failed to create items table"
    exit 1
fi

if ! load_items_data; then
    echo "✗ Failed to load items data"
    exit 1
fi

echo "✓ Items table created successfully!"