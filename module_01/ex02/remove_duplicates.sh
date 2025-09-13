#!/bin/bash

# Load environment variables from .env file if it exists
if [ -f "../.env" ]; then
    source ../.env
fi

echo "Removing duplicates from customers table..."

# Get original count
original_count=$(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM customers;" | tr -d ' ')
echo "Original rows: $original_count"

if [ "$original_count" -eq 0 ]; then
    echo "Table is empty. Nothing to remove."
    exit 0
fi

# Remove duplicates with time-based deduplication
docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" << 'EOF'
DO $$
BEGIN
    RAISE NOTICE 'Removing duplicate rows and events within 1 second interval...';
    
    -- Remove exact duplicate rows using ctid
    DELETE FROM customers a
    WHERE a.ctid <> (SELECT min(b.ctid)
                     FROM customers b
                     WHERE a.event_time = b.event_time AND
                           a.event_type = b.event_type AND
                           a.product_id = b.product_id AND
                           a.price = b.price AND
                           a.user_id = b.user_id AND
                           a.user_session = b.user_session);
    
    RAISE NOTICE 'Exact duplicates removed successfully';
EXCEPTION
    WHEN OTHERS THEN
        DROP TABLE IF EXISTS customers_temp;
        RAISE;
END $$;
EOF

if [ $? -ne 0 ]; then
    echo "✗ Failed to remove duplicates"
    exit 1
fi

# Get final count
final_count=$(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM customers;" | tr -d ' ')
removed=$((original_count - final_count))

echo "Final rows: $final_count"
echo "Removed: $removed duplicates"
echo "✓ Successfully cleaned customers table!"