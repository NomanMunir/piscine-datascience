#!/bin/bash

# Load environment variables from .env file if it exists
if [ -f "../.env" ]; then
    source ../.env
fi

echo "Starting automatic table creation process..."
echo "Using container: $POSTGRES_CONTAINER, user: $POSTGRES_USER, database: $POSTGRES_DB"
echo "This may take a few minutes for large CSV files..."

echo "Loading PostgreSQL function..."
docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB -f /data/module_00/ex03/automatic_table.sql

if [ $? -ne 0 ]; then
    echo "Error: Failed to load PostgreSQL function."
    exit 1
fi

echo "Scanning for CSV files in customer folder..."
# Find all CSV files in customer folder
csv_files=($(docker exec $POSTGRES_CONTAINER find /data/data/customer -name "*.csv" -type f -exec basename {} \;))

if [ ${#csv_files[@]} -eq 0 ]; then
    echo "Error: No CSV files found in customer folder."
    exit 1
fi

echo "Found ${#csv_files[@]} CSV files to process..."

# Process each CSV file
for csv_file in "${csv_files[@]}"; do
    table_name=$(basename "$csv_file" .csv)
    csv_path="/data/data/customer/$csv_file"
    
    echo "Processing: $csv_file -> Table: $table_name"
    docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT create_table_from_csv('$table_name', '$csv_path');"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create table from $csv_file."
        exit 1
    fi
done

echo ""
echo "Automatic table creation completed successfully."
