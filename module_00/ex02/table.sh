#!/bin/bash

CONTAINER_NAME=${POSTGRES_CONTAINER:-postgres}
DB_USER=${POSTGRES_USER:-nmunir}
DB_NAME=${POSTGRES_DB:-piscineds}

echo "Creating table and loading data for October 2022..."
echo "Using container: $CONTAINER_NAME, user: $DB_USER, database: $DB_NAME"
echo "This may take a few minutes for large CSV files..."

echo "Executing SQL script..."
docker exec -i $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -f /data/module_00/ex02/table.sql

if [ $? -eq 0 ]; then
    echo "Table creation and data loading completed successfully."
else
    echo "Error: Failed to create table and load data."
    exit 1
fi