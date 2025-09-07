#!/bin/bash
set -e

# Exercise 04: Items table creation script
echo "🚀 Starting PostgreSQL for Exercise 04 - Items table creation..."

# Start PostgreSQL in background
docker-entrypoint.sh postgres &
POSTGRES_PID=$!

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
until pg_isready -h localhost -p 5432 -U "$POSTGRES_USER"; do
  echo "Waiting for PostgreSQL..."
  sleep 2
done

echo "✅ PostgreSQL is ready!"

# Create the items table from the item.csv file
echo "📝 Creating items table from item.csv..."
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /scripts/items_table.sql

# Verify the table was created successfully
echo "🔍 Verifying items table creation..."
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
    SELECT 
        'items' as table_name,
        COUNT(*) as row_count,
        pg_size_pretty(pg_total_relation_size('items')) as table_size
    FROM items;
"

echo "📊 Items table structure:"
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
    SELECT 
        column_name,
        data_type,
        is_nullable,
        character_maximum_length
    FROM information_schema.columns 
    WHERE table_name = 'items' 
    ORDER BY ordinal_position;
"

echo "🎉 Exercise 04 completed successfully!"
echo "✅ Table 'items' created with three different data types:"
echo "   - BIGINT (product_id, category_id)"
echo "   - VARCHAR(255) (category_code)"  
echo "   - TEXT (brand)"

echo ""
echo "🌐 Database is ready! You can connect via pgAdmin at http://localhost:8080"
echo "📝 Use these credentials:"
echo "   Email: admin@piscineds.com"
echo "   Password: admin123"

# Keep PostgreSQL running
wait $POSTGRES_PID