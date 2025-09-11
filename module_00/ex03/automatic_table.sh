#!/bin/bash

echo "🚀 Starting automatic table creation process..."

echo "📁 Loading automatic_table.sql function..."
docker exec -i postgres psql -U nmunir -d piscineds -f /data/piscine-datascience/module_00/ex03/automatic_table.sql

if [ $? -ne 0 ]; then
    echo "❌ Failed to load function. Exiting."
    exit 1
fi

csv_files=(
    "data_2022_oct.csv"
    "data_2022_nov.csv"
    "data_2022_dec.csv"
    "data_2023_jan.csv"
)

echo "📋 Found ${#csv_files[@]} CSV files to process"

for csv_file in "${csv_files[@]}"; do
    table_name=$(basename "$csv_file" .csv)
    csv_path="/data/data/customer/$csv_file"
    
    echo "🔄 Processing: $csv_file → Table: $table_name"
    
    # Call the PostgreSQL function
    result=$(docker exec -i postgres psql -U nmunir -d piscineds -c "SELECT create_table_from_csv('$table_name', '$csv_path');" -t -A)
    
    if [ $? -eq 0 ]; then
        echo "✅ $result"
    else
        echo "❌ Failed to process $csv_file"
    fi
done

echo ""
echo "📊 Summary of created tables:"
docker exec -i postgres psql -U nmunir -d piscineds -c "
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as columns,
    pg_size_pretty(pg_total_relation_size(table_name::regclass)) as size
FROM information_schema.tables t
WHERE table_schema = 'public' 
AND table_name LIKE 'data_202%'
ORDER BY table_name;"

echo ""
echo "🎉 Automatic table creation completed!"
