#!/bin/bash
set -e

# Custom entrypoint script for PostgreSQL with automatic table creation

echo "🚀 Starting PostgreSQL with custom initialization..."

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

# Run our SQL script
echo "📊 Creating table and loading data..."
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /scripts/table.sql

echo "🎉 Table created and data loaded successfully!"

# Keep PostgreSQL running in foreground
wait $POSTGRES_PID
