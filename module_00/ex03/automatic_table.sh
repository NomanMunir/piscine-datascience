#!/bin/bash

echo "Starting automatic table creation process..."

echo "Loading function and creating tables..."
docker exec -i postgres psql -U nmunir -d piscineds -f /data/module_00/ex03/automatic_table.sql

if [ $? -ne 0 ]; then
    echo "Error: Failed to load function. Exiting."
    exit 1
fi

# Find all CSV files in customer folder
csv_files=($(docker exec postgres find /data/data/customer -name "*.csv" -type f -exec basename {} \;))

if [ ${#csv_files[@]} -eq 0 ]; then
    echo "Error: No CSV files found in customer folder."
    exit 1
fi

echo "Processing ${#csv_files[@]} CSV files..."

# Process each CSV file
for csv_file in "${csv_files[@]}"; do
    table_name=$(basename "$csv_file" .csv)
    csv_path="/data/data/customer/$csv_file"
    
    echo "Creating table: $table_name"
    docker exec -i postgres psql -U nmunir -d piscineds -c "SELECT create_table_from_csv('$table_name', '$csv_path');" -q
done

echo "Automatic table creation completed."
