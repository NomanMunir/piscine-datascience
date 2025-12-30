#!/bin/bash

if [ -f "../../.env" ]; then
    source ../../.env
fi



check_existing_data() {
    local existing_rows=$(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM data_2022_oct;" 2>/dev/null | tr -d ' ')
    
    if [ "$existing_rows" -gt 0 ] 2>/dev/null; then
        echo "Table already contains $existing_rows rows. Skipping data load."
        return 0
    else
        return 1
    fi
}

create_table_structure() {
    echo "Creating table structure and indexes..."
    
    docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" << 'EOF'
CREATE TABLE IF NOT EXISTS data_2022_oct (
    event_time TIMESTAMP WITH TIME ZONE NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    product_id BIGINT NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    user_id INTEGER NOT NULL,
    user_session UUID
);

CREATE INDEX IF NOT EXISTS idx_data_2022_oct_event_time ON data_2022_oct(event_time);
CREATE INDEX IF NOT EXISTS idx_data_2022_oct_user_id ON data_2022_oct(user_id);
CREATE INDEX IF NOT EXISTS idx_data_2022_oct_product_id ON data_2022_oct(product_id);
EOF

    if [ $? -ne 0 ]; then
        echo "✗ Failed to create table structure"
        return 1
    fi
    
    return 0
}

load_csv_data() {
    echo "Loading CSV data..."
    
    docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" << EOF
COPY data_2022_oct(event_time, event_type, product_id, price, user_id, user_session)
FROM '$CONTAINER_DATA_PATH/customer/data_2022_oct.csv'
WITH CSV HEADER DELIMITER ',';
EOF

    if [ $? -eq 0 ]; then
        local final_count=$(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM data_2022_oct;" | tr -d ' ')
        echo "✓ Successfully loaded $final_count rows"
        return 0
    else
        echo "✗ Failed to load data"
        return 1
    fi
}

echo "Creating table and loading data for October 2022..."

if check_existing_data; then
    exit 0
fi

if ! create_table_structure; then
    exit 1
fi

if ! load_csv_data; then
    exit 1
fi

echo "✓ Successfully created table and loaded data!"