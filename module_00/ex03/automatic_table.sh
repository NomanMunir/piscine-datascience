#!/bin/bash

CONTAINER_NAME=${POSTGRES_CONTAINER:-postgres}
DB_USER=${POSTGRES_USER:-nmunir}
DB_NAME=${POSTGRES_DB:-piscineds}
QUERY_FILE="/data/module_00/ex03/automatic_table.sql"

echo "Starting automatic table creation process..."
echo "Using container: $CONTAINER_NAME, user: $DB_USER, database: $DB_NAME"

echo "Loading function and creating tables..."
docker exec -i $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -f $QUERY_FILE

if [ $? -ne 0 ]; then
    echo "Error: Failed to load function. Exiting."
    exit 1
fi

# Find all CSV files in customer folder
csv_files=($(docker exec $CONTAINER_NAME find /data/data/customer -name "*.csv" -type f -exec basename {} \;))

if [ ${#csv_files[@]} -eq 0 ]; then
    echo "Error: No CSV files found in customer folder."
    exit 1
fi

echo "Processing ${#csv_files[@]} CSV files..."

for csv_file in "${csv_files[@]}"; do
    table_name=$(basename "$csv_file" .csv)
    csv_path="/data/data/customer/$csv_file"
    
    echo "Creating table: $table_name"
    docker exec -i $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c "SELECT create_table_from_csv('$table_name', '$csv_path');" -q
done

echo "Automatic table creation completed."
