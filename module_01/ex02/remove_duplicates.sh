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

# Remove duplicates with time-based deduplication (optimized for large datasets)
docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" << 'EOF'
DO $$
BEGIN
    RAISE NOTICE 'Starting optimized duplicate removal for large dataset...';
    
    -- Create index for performance boost
    RAISE NOTICE 'Creating temporary index for performance...';
    CREATE INDEX IF NOT EXISTS idx_customers_dedup_temp 
    ON customers (user_id, product_id, event_type, price, user_session, event_time);
    
    -- Stage 1: Remove exact duplicates using efficient window function
    RAISE NOTICE 'Stage 1: Removing exact duplicates...';
    DELETE FROM customers 
    WHERE ctid NOT IN (
        SELECT ctid FROM (
            SELECT ctid,
                   ROW_NUMBER() OVER (
                       PARTITION BY event_time, event_type, product_id, price, user_id, user_session 
                       ORDER BY ctid
                   ) as rn
            FROM customers
        ) ranked 
        WHERE rn = 1
    );
    
    RAISE NOTICE 'Stage 1 completed: Exact duplicates removed';
    
    -- Stage 2: Remove events within 1-second interval (same user, product, type)
    RAISE NOTICE 'Stage 2: Removing events within 1-second interval...';
    DELETE FROM customers a
    WHERE EXISTS (
        SELECT 1 FROM customers b
        WHERE a.user_id = b.user_id 
          AND a.product_id = b.product_id 
          AND a.event_type = b.event_type 
          AND a.price = b.price 
          AND a.user_session = b.user_session
          AND ABS(EXTRACT(EPOCH FROM (a.event_time - b.event_time))) <= 1
          AND a.event_time > b.event_time  -- Keep the earlier event
          AND a.ctid > b.ctid  -- Use ctid as tiebreaker
    );
    
    RAISE NOTICE 'Stage 2 completed: 1-second interval duplicates removed';
    
    -- Drop temporary index
    DROP INDEX IF EXISTS idx_customers_dedup_temp;
    
    RAISE NOTICE 'All duplicate removal operations completed successfully';
EXCEPTION
    WHEN OTHERS THEN
        DROP INDEX IF EXISTS idx_customers_dedup_temp;
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