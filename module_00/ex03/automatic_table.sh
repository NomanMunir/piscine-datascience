#!/bin/bash

# Load environment variables from .env file if it exists
if [ -f "../../.env" ]; then
    source ../../.env
fi



check_existing_data() {
    local table_name=$1
    local existing_rows=$(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM $table_name;" 2>/dev/null | tr -d ' ')
    
    if [ "$existing_rows" -gt 0 ] 2>/dev/null; then
        echo "Table $table_name already contains $existing_rows rows. Skipping."
        return 0  # Table exists with data
    else
        return 1  # Table is empty or doesn't exist
    fi
}

create_table_structure() {
    local table_name=$1
    
    echo "Creating table structure and indexes..."
    
    docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" << EOF
-- Create table structure
CREATE TABLE IF NOT EXISTS $table_name (
    event_time TIMESTAMP WITH TIME ZONE NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    product_id BIGINT NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    user_id INTEGER NOT NULL,
    user_session UUID
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_${table_name}_event_time ON $table_name(event_time);
CREATE INDEX IF NOT EXISTS idx_${table_name}_user_id ON $table_name(user_id);
CREATE INDEX IF NOT EXISTS idx_${table_name}_product_id ON $table_name(product_id);
EOF

    if [ $? -ne 0 ]; then
        echo "✗ Failed to create table structure for $table_name"
        return 1
    fi
    
    return 0
}

load_csv_data() {
    local table_name=$1
    local csv_path=$2
    
    echo "Loading CSV data..."
    
    docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" << EOF
COPY $table_name(event_time, event_type, product_id, price, user_id, user_session)
FROM '$csv_path'
WITH CSV HEADER DELIMITER ',';
EOF

    if [ $? -eq 0 ]; then
        local final_count=$(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM $table_name;" | tr -d ' ')
        echo "✓ Successfully loaded $final_count rows into $table_name"
        return 0
    else
        echo "✗ Failed to load data for $table_name"
        return 1
    fi
}

process_csv_file() {
    local csv_file=$1
    local table_name=$(basename "$csv_file" .csv)
    local csv_path="$CONTAINER_DATA_PATH/customer/$csv_file"
    
    echo ""
    echo "Processing: $csv_file -> Table: $table_name"
    
    if check_existing_data "$table_name"; then
        return 0
    fi
    
    if ! create_table_structure "$table_name"; then
        return 1
    fi
    
    # Load CSV data
    if ! load_csv_data "$table_name" "$csv_path"; then
        return 1
    fi
    
    return 0
}

echo "Starting automatic table creation for all CSV files..."

echo "Scanning for CSV files..."
csv_files=($(docker exec "$POSTGRES_CONTAINER" find "$CONTAINER_DATA_PATH/customer" -name "*.csv" -type f -exec basename {} \;))

if [ ${#csv_files[@]} -eq 0 ]; then
    echo "✗ No CSV files found in customer folder"
    exit 1
fi

echo "Found ${#csv_files[@]} CSV files: ${csv_files[*]}"

success_count=0
for csv_file in "${csv_files[@]}"; do
    if process_csv_file "$csv_file"; then
        success_count=$((success_count + 1))
    else
        echo "✗ Failed to process $csv_file"
        exit 1
    fi
done

echo ""
echo "✓ Automatic table creation completed successfully!"
echo "✓ Processed $success_count/${#csv_files[@]} CSV files"
