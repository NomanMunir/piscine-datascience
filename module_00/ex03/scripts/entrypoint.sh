#!/bin/bash
set -e

# Truly automatic entrypoint script - discovers CSV files dynamically!
echo "🚀 Starting PostgreSQL with TRULY automatic table creation..."

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

# First, create the function
echo "📝 Creating table creation function..."
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /scripts/automatic_table.sql

# Now automatically discover and process ALL CSV files
echo "� Discovering CSV files automatically..."

# Find all CSV files in the customer directory
CSV_FILES=$(find /data/customer -name "*.csv" -type f)

if [ -z "$CSV_FILES" ]; then
    echo "❌ No CSV files found in /data/customer/"
    exit 1
fi

echo "📁 Found CSV files:"
echo "$CSV_FILES"
echo ""

# Process each CSV file automatically
for csv_file in $CSV_FILES; do
    # Extract filename without path and extension
    filename=$(basename "$csv_file" .csv)
    
    echo "📊 Processing: $filename"
    echo "   File: $csv_file"
    
    # Call our PostgreSQL function to create table and load data
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
        SELECT create_table_from_csv('$filename', '$csv_file');
    "
    
    echo "✅ Completed: $filename"
    echo ""
done

echo "🎉 All CSV files processed automatically!"

# Show final summary
echo "📋 Final Summary of ALL created tables:"
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
SELECT 
    tablename,
    pg_size_pretty(pg_total_relation_size(tablename)) as size,
    (SELECT COUNT(*) 
     FROM information_schema.columns 
     WHERE table_name = tablename) as columns
FROM pg_tables 
WHERE tablename LIKE 'data_%'
ORDER BY tablename;
"

echo ""
echo "🔢 Row counts for each table:"
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
DO \$\$
DECLARE
    table_record RECORD;
    row_count INTEGER;
BEGIN
    FOR table_record IN 
        SELECT tablename FROM pg_tables WHERE tablename LIKE 'data_%'
    LOOP
        EXECUTE format('SELECT COUNT(*) FROM %I', table_record.tablename) INTO row_count;
        RAISE NOTICE '📊 Table %: % rows', table_record.tablename, row_count;
    END LOOP;
END;
\$\$;
"

# Keep PostgreSQL running in foreground
wait $POSTGRES_PID
