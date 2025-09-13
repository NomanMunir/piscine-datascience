#!/bin/bash

# Load environment variables from .env file if it exists
if [ -f "../.env" ]; then
    source ../.env
fi

echo "Using container: $POSTGRES_CONTAINER, user: $POSTGRES_USER, database: $POSTGRES_DB"
echo "Creating items table..."

# Execute SQL file
docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /app/ex04/items_table.sql

if [ $? -ne 0 ]; then
    echo "Error: Failed to create items table."
    exit 1
fi
echo "Items table created successfully!"