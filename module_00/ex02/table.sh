#!/bin/bash

# Load environment variables from .env file if it exists
if [ -f "../.env" ]; then
    source ../.env
fi

echo "Creating table and loading data for October 2022..."
echo "Using container: $POSTGRES_CONTAINER, user: $POSTGRES_USER, database: $POSTGRES_DB"
echo "This may take a few minutes for large CSV files..."

echo "Executing SQL script..."
docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB -f /app/ex02/table.sql

if [ $? -eq 0 ]; then
    echo "Table creation and data loading completed successfully."
else
    echo "Error: Failed to create table and load data."
    exit 1
fi