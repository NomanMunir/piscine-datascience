#!/bin/bash

# Load environment variables from .env file if it exists
if [ -f "../.env" ]; then
    source ../.env
fi

# Function to insert data from a specific table into customers
insert_into_customers() {
    local source_table=$1
    echo "Inserting data from $source_table..."
    
    docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
        INSERT INTO customers (event_time, event_type, product_id, price, user_id, user_session)
        SELECT event_time, event_type, product_id, price, user_id, user_session
        FROM $source_table;
    "
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully inserted data from $source_table"
    else
        echo "✗ Failed to insert data from $source_table"
        return 1
    fi
}

echo "Creating customers table from all data_202* tables..."

# Create customers table structure
docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
CREATE TABLE IF NOT EXISTS customers (
    event_time TIMESTAMP WITH TIME ZONE,
    event_type VARCHAR(50),
    product_id BIGINT,
    price NUMERIC(10,2),
    user_id INTEGER,
    user_session UUID
);
"

# Check if table already has data
existing_rows=$(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM customers;" | tr -d ' ')

if [ "$existing_rows" -gt 0 ]; then
    echo "Customers table already contains $existing_rows rows. Skipping data load."
    exit 0
fi

# Get all data_202* tables and store in array
echo "Finding all data_202* tables..."
tables=($(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public' AND tablename LIKE 'data_202%'
    ORDER BY tablename;
" | tr -d ' '))

if [ ${#tables[@]} -eq 0 ]; then
    echo "No data_202* tables found!"
    exit 1
fi

echo "Found ${#tables[@]} tables to process: ${tables[*]}"

# Loop through each table and insert data
total_tables=${#tables[@]}
current_table=0

for table in "${tables[@]}"; do
    current_table=$((current_table + 1))
    echo "[$current_table/$total_tables] Processing $table..."
    
    if insert_into_customers "$table"; then
        echo "Progress: $current_table/$total_tables tables completed"
    else
        echo "Error: Failed to process $table"
        exit 1
    fi
done

# Get final count
final_count=$(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM customers;" | tr -d ' ')

echo ""
echo "✓ Successfully created customers table!"
echo "✓ Total rows inserted: $final_count"
echo "✓ Tables processed: ${#tables[@]}"