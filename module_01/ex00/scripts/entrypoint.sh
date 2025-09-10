#!/bin/bash
set -e

# Piscine Data Science - Automatic Database Initialization
echo "🚀 Starting PostgreSQL with automatic database initialization..."

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

# Run the master initialization script
echo "🔧 Running database initialization..."
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /scripts/init.sql

echo ""
echo "🎉 Database initialization completed successfully!"
echo "📋 All tables have been created and populated with data"
echo ""
echo "🌐 You can now:"
echo "   • Access pgAdmin at http://localhost:8080"
echo "   • Run exercises with: docker exec -it postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -f /scripts/ex01_customers_table.sql"
echo "   • Or use pgAdmin Query Tool to run exercise scripts"
echo ""
echo "📝 pgAdmin credentials:"
echo "   Email: admin@piscineds.com"
echo "   Password: admin123"
echo ""
echo "🔄 PostgreSQL is running. Press Ctrl+C to stop."

# Keep PostgreSQL running in foreground
wait $POSTGRES_PID
