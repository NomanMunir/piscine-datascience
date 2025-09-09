#!/bin/bash
set -e

# Exercise 01: Join all customer data tables
echo "🚀 Starting PostgreSQL for Exercise 01 - Joining customer tables into 'customers' table"

# Start PostgreSQL in background
docker-entrypoint.sh postgres &
POSTGRES_PID=$!

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
until pg_isready -h localhost -p 5432 -U "$POSTGRES_USER" -d "$POSTGRES_DB"; do
  echo "Waiting for PostgreSQL..."
  sleep 2
done

echo "✅ PostgreSQL is ready!"

# Give it a moment to fully initialize
sleep 3

# First, create the automatic table function from Module 00
echo "� Setting up automatic table creation function..."
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /scripts/automatic_table.sql

# Find all CSV files and create tables for them
echo "🔍 Searching for CSV files in /data/customer/..."
csv_files=$(find /data/customer -name "*.csv" -type f 2>/dev/null || echo "")

if [ -z "$csv_files" ]; then
    echo "❌ No CSV files found in /data/customer/"
    echo "💡 Make sure the data volume is properly mounted"
else
    echo "✅ Found CSV files. Creating data tables..."
    
    # Create tables for each CSV file
    for csv_file in $csv_files; do
        # Extract filename without path and extension for table name
        filename=$(basename "$csv_file" .csv)
        table_name="$filename"
        
        echo "� Creating table '$table_name' from '$csv_file'..."
        
        # Call the function to create table and load data
        psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT create_table_from_csv('$table_name', '$csv_file');"
    done
fi

# Check how many data tables we created
echo "🔍 Checking created data_202* tables..."
table_count=$(psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name LIKE 'data_202%';" 2>/dev/null | tr -d ' ' || echo "0")

if [ "$table_count" -eq 0 ]; then
    echo "❌ No data_202* tables were created!"
    echo "💡 Check if CSV files are properly mounted in /data/customer/"
    echo ""
    echo "🌐 PostgreSQL is running. You can connect via pgAdmin at http://localhost:8080"
    echo "📝 Use these credentials:"
    echo "   Email: admin@piscineds.com"
    echo "   Password: admin123"
else
    echo "✅ Found $table_count data_202* tables created successfully"
    
    # Now execute the customers table creation script to join all tables
    echo "📊 Creating customers table by joining all data_202* tables..."
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /scripts/customers_table.sql
    
    echo ""
    echo "🎉 Exercise 01 completed successfully!"
    echo "📋 Summary:"
    echo "   ✅ Created $table_count data_202* tables from CSV files"
    echo "   ✅ Joined all data_202* tables into 'customers' table"
    echo "   ✅ Added source_table column to track data origin"
    echo "   ✅ Created performance indexes"
    echo "   ✅ Generated summary statistics"
    echo ""
    echo "🌐 Database is ready! You can connect via pgAdmin at http://localhost:8080"
    echo "📝 Use these credentials:"
    echo "   Email: admin@piscineds.com"
    echo "   Password: admin123"
fi

# Keep PostgreSQL running
echo ""
echo "🔄 PostgreSQL is running. Press Ctrl+C to stop."
wait $POSTGRES_PID
