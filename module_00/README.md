# Module 00 - Database Creation and Management

This module covers the fundamentals of database creation, table management, and data loading using PostgreSQL and Docker.

## Overview

Module 00 introduces data science students to database concepts through hands-on exercises using PostgreSQL, pgAdmin, and Docker Compose. Each exercise builds upon the previous one, progressing from basic database setup to automated table creation with comprehensive error handling and progress tracking.

## Prerequisites

- Docker and Docker Compose installed
- Basic understanding of SQL
- Command line familiarity (bash/WSL for Windows users)

## Environment Configuration

All exercises use a centralized `.env` file for configuration:

```bash
# Database Configuration
POSTGRES_USER=nmunir
POSTGRES_PASSWORD=mysecretpassword
POSTGRES_DB=piscineds
POSTGRES_CONTAINER=postgres

# Data paths
DATA_PATH=/app/data

# pgAdmin Configuration
PGADMIN_DEFAULT_EMAIL=admin@piscineds.com
PGADMIN_DEFAULT_PASSWORD=admin123
```

## Exercises

### Exercise 00 - PostgreSQL & pgAdmin Setup
**Directory:** `ex00/`  
**Files:** `docker-compose.yml`  
**Objective:** Set up PostgreSQL database and pgAdmin with Docker Compose  
**Features:** Health checks, automatic restarts, persistent volumes  
**What you'll learn:** Docker containerization, PostgreSQL basics, environment configuration

### Exercise 01 - Database Visualization
**Directory:** `ex01/`  
**Files:** `.gitkeep` (documentation only)  
**Objective:** Use pgAdmin or other tools to visualize the database  
**Turn-in:** Nothing to turn in (tool-based exercise)  
**What you'll learn:** Database administration tools, data visualization, GUI interfaces

### Exercise 02 - Table Creation with 6 Data Types
**Directory:** `ex02/`  
**Files:** `table.sql`, `table.sh`  
**Objective:** Create `data_2022_oct` table with 6 different PostgreSQL data types  
**Features:** Duplicate prevention, progress indicators, automatic .env loading  
**Data Types:** TIMESTAMP WITH TIME ZONE, VARCHAR, BIGINT, NUMERIC, INTEGER, UUID  
**What you'll learn:** SQL data types, table creation, CSV data loading, error handling

### Exercise 03 - Automated Table Creation
**Directory:** `ex03/`  
**Files:** `automatic_table.sql`, `automatic_table.sh`  
**Objective:** Create PostgreSQL function to automatically process all CSV files  
**Features:** Dynamic table creation, batch processing, comprehensive logging  
**What you'll learn:** PL/pgSQL functions, dynamic SQL, automation, batch processing

### Exercise 04 - Items Table with 3+ Data Types
**Directory:** `ex04/`  
**Files:** `items_table.sql`, `items_table.sh`  
**Objective:** Create `items` table using column names from item.csv  
**Features:** 3+ data types, exception handling, configurable paths  
**Data Types:** BIGINT, VARCHAR(255), TEXT  
**What you'll learn:** Schema design, data type selection, exception handling

## Data Structure

The module uses e-commerce data stored in CSV format:
- **Customer data:** Transaction records with timestamps, events, products, prices, and user sessions
- **Item data:** Product catalog with categories, brands, and identifiers

## Common Commands

### Starting the Database (from ex00/)
```bash
cd ex00
docker-compose up -d
```

### Running Individual Exercises
```bash
# Exercise 02 - October 2022 data
cd ex02
./table.sh

# Exercise 03 - All customer CSV files
cd ex03
./automatic_table.sh

# Exercise 04 - Items table
cd ex04
./items_table.sh
```

### Viewing Logs
```bash
docker logs postgres
docker logs pgadmin
```

### Accessing pgAdmin
- URL: http://localhost:4001
- Email: admin@piscineds.com  
- Password: admin123

### Database Connection (for pgAdmin)
- Host: postgres
- Port: 5432
- Database: piscineds
- Username: nmunir
- Password: mysecretpassword

### Stopping Services
```bash
cd ex00
docker-compose down
```

### Full Reset (removes all data)
```bash
cd ex00
docker-compose down -v
docker-compose up -d
```

## Container File Structure

The Docker volume mount `../:/app` creates this structure inside containers:

```
/app/
├── data/
│   ├── customer/          # Customer CSV files
│   │   ├── data_2022_oct.csv
│   │   ├── data_2022_nov.csv
│   │   └── ...
│   └── item/
│       └── item.csv       # Item catalog
├── ex00/
│   └── docker-compose.yml
├── ex01/
│   └── .gitkeep
├── ex02/
│   ├── table.sql          # Single table creation
│   └── table.sh
├── ex03/
│   ├── automatic_table.sql # Batch processing function
│   └── automatic_table.sh
├── ex04/
│   ├── items_table.sql    # Items table creation
│   └── items_table.sh
└── .env                   # Environment configuration
```

## Database Schema

### Customer Tables (ex02, ex03)
**Table names:** `data_2022_oct`, `data_2022_nov`, `data_2022_dec`, `data_2023_jan`

| Column | Data Type | Description |
|--------|-----------|-------------|
| `event_time` | TIMESTAMP WITH TIME ZONE | Event timestamp with timezone |
| `event_type` | VARCHAR(50) | Event type (purchase, cart, etc.) |
| `product_id` | BIGINT | Product identifier |
| `price` | NUMERIC(10,2) | Product price with 2 decimal places |
| `user_id` | INTEGER | User identifier |
| `user_session` | UUID | Session identifier |

### Items Table (ex04)
**Table name:** `items`

| Column | Data Type | Description |
|--------|-----------|-------------|
| `product_id` | BIGINT | Product identifier |
| `category_id` | BIGINT | Category identifier |
| `category_code` | VARCHAR(255) | Category code (nullable) |
| `brand` | TEXT | Brand name (nullable) |

## Script Features

### All Scripts Include:
- ✅ **Environment Configuration**: Automatic .env file loading
- ✅ **Line Ending Fix**: Automatic Windows to Unix conversion
- ✅ **Progress Indicators**: Real-time feedback with PostgreSQL RAISE NOTICE
- ✅ **Duplicate Prevention**: Skip loading if data already exists
- ✅ **Error Handling**: Comprehensive exception handling
- ✅ **Configurable Paths**: Use DATA_PATH from .env file

### Error Handling Features:
- Container availability checks
- SQL execution validation
- CSV file existence verification
- Duplicate data detection
- Automatic rollback on errors

## Key Learning Outcomes

1. **Docker Containerization:** PostgreSQL and pgAdmin setup with Docker Compose
2. **Environment Management:** Centralized configuration with .env files
3. **PostgreSQL Data Types:** Working with 6+ different data types (BIGINT, VARCHAR, TEXT, UUID, TIMESTAMP, NUMERIC, INTEGER)
4. **Data Loading:** Efficient CSV data loading with COPY commands
5. **PL/pgSQL Programming:** Dynamic table creation with stored functions
6. **Error Handling:** Comprehensive exception handling and duplicate prevention
7. **Automation:** Batch processing and progress tracking
8. **Shell Scripting:** Environment-aware bash scripts with error checking
9. **Cross-Platform Development:** Windows line ending handling for WSL compatibility

## Troubleshooting

### Common Issues

1. **Port Conflicts:** 
   - PostgreSQL: Check port 5432 availability
   - pgAdmin: Check port 4001 availability
   
2. **Container Issues:**
   ```bash
   # Check container status
   docker ps -a
   
   # View container logs
   docker logs postgres
   docker logs pgadmin
   ```

3. **Line Ending Issues (Windows):**
   - Scripts automatically fix .env file line endings
   - Use WSL/Git Bash for running shell scripts
   
4. **Permission Issues:**
   ```bash
   # Make scripts executable
   chmod +x *.sh
   ```

5. **Database Connection:**
   - Ensure containers are running: `docker ps`
   - Check .env file configuration
   - Verify network connectivity between containers

### Useful Commands

```bash
# Check running containers
docker ps

# View real-time logs
docker logs -f postgres

# Connect to PostgreSQL directly
docker exec -it postgres psql -U nmunir -d piscineds

# Check table contents
docker exec -it postgres psql -U nmunir -d piscineds -c "SELECT COUNT(*) FROM data_2022_oct;"

# Reset specific table
docker exec -it postgres psql -U nmunir -d piscineds -c "DROP TABLE IF EXISTS items;"

# Complete environment reset
cd ex00
docker-compose down -v
docker-compose up -d
```

### Script Debugging

```bash
# Test .env loading
cd ex02
source ../.env
echo $POSTGRES_CONTAINER

# Verify file paths in container
docker exec postgres ls -la /app/data/customer/
docker exec postgres ls -la /app/ex02/

# Check PostgreSQL function (ex03)
docker exec -it postgres psql -U nmunir -d piscineds -c "\df create_table_from_csv"
```

## Data Statistics

- **Customer Data:** ~25M+ records across multiple monthly files
- **Item Data:** 109,579 product records
- **File Sizes:** Varies from a few MB to several hundred MB per CSV file

## Best Practices Learned

1. Always use appropriate data types for your data
2. Consider NULL constraints based on your data quality
3. Use indexes for frequently queried columns
4. Automate repetitive tasks with scripts
5. Use Docker volumes for data persistence
6. Monitor container logs for debugging

---

*Part of the 42 Data Science Piscine curriculum*
