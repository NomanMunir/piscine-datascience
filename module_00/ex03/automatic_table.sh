#!/bin/bash

# Load configuration from environment variables with defaults
CONTAINER_NAME=${POSTGRES_CONTAINER:-postgres}
DB_USER=${POSTGRES_USER:-nmunir}
DB_NAME=${POSTGRES_DB:-piscineds}

echo "Starting automatic table creation process..."
echo "Using container: $CONTAINER_NAME, user: $DB_USER, database: $DB_NAME"
echo "This may take a few minutes for large CSV files..."

echo "Loading PostgreSQL function..."
docker exec -i $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -f /data/module_00/ex03/automatic_table.sql

if [ $? -ne 0 ]; then
    echo "Error: Failed to load PostgreSQL function."
    exit 1
fi

echo "Scanning for CSV files in customer folder..."
# Find all CSV files in customer folder
csv_files=($(docker exec $CONTAINER_NAME find /data/data/customer -name "*.csv" -type f -exec basename {} \;))

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
    docker exec -i $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c "SELECT create_table_from_csv('$table_name', '$csv_path');"
done

echo ""
echo "Automatic table creation completed successfully."
