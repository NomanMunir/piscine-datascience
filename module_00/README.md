# Module 00 - Database Creation and Management

This module covers the fundamentals of database creation, table management, and data loading using PostgreSQL and Docker.

## Overview

Module 00 introduces data science students to database concepts through hands-on exercises using PostgreSQL, pgAdmin, and Docker Compose. Each exercise builds upon the previous one, progressing from basic database setup to automated table creation with comprehensive error handling and progress tracking.

## Learning Objectives

- Set up PostgreSQL database using Docker
- Learn basic SQL operations and table management
- Understand data loading and validation
- Practice automated database operations
- Implement error handling and progress tracking

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
**Files:** `table.sh`  
**Objective:** Create `data_2022_oct` table with 6 different PostgreSQL data types  
**Features:** Function-based script, duplicate prevention, performance indexes  
**Data Types:** TIMESTAMP WITH TIME ZONE, VARCHAR, BIGINT, NUMERIC, INTEGER, UUID  
**What you'll learn:** SQL data types, table creation, CSV data loading, modular scripting

### Exercise 03 - Automated Table Creation
**Directory:** `ex03/`  
**Files:** `automatic_table.sh`  
**Objective:** Automatically process all CSV files with function-based approach  
**Features:** Reusable functions, batch processing, error handling per file  
**What you'll learn:** Function-based scripting, dynamic processing, code reusability

### Exercise 04 - Items Table with 3+ Data Types
**Directory:** `ex04/`  
**Files:** `items_table.sh`  
**Objective:** Create `items` table using function-based approach  
**Features:** Modular functions, performance indexes, clean code structure  
**Data Types:** BIGINT, VARCHAR(255), TEXT  
**What you'll learn:** Schema design, function modularity, clean coding practices

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
│   └── table.sh           # Function-based table creation
├── ex03/
│   └── automatic_table.sh # Function-based batch processing
├── ex04/
│   └── items_table.sh     # Function-based items table
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
- ✅ **Function-Based Architecture**: Modular, reusable functions for better code organization
- ✅ **Environment Configuration**: Automatic .env file loading with DATA_PATH support
- ✅ **Clean Code**: No comments, clean SQL, simple structure
- ✅ **Duplicate Prevention**: Smart checks to skip loading if data already exists
- ✅ **Error Handling**: Proper return codes and clear error messages
- ✅ **Performance Indexes**: Automatic index creation for better query performance

### Function Structure:
- **check_existing_data()**: Verify if table already contains data
- **create_table_structure()**: Create table schema and performance indexes
- **load_csv_data()**: Load CSV data with proper error handling
- **process_csv_file()**: Complete file processing (ex03 only)

### Error Handling Features:
- Container availability checks
- SQL execution validation
- CSV file existence verification
- Duplicate data detection
- Function-level error propagation

## Key Learning Outcomes

1. **Docker Containerization:** PostgreSQL and pgAdmin setup with Docker Compose
2. **Environment Management:** Centralized configuration with .env files
3. **PostgreSQL Data Types:** Working with 6+ different data types (BIGINT, VARCHAR, TEXT, UUID, TIMESTAMP, NUMERIC, INTEGER)
4. **Data Loading:** Efficient CSV data loading with COPY commands
5. **Function-Based Scripting:** Modular, reusable bash functions for better code organization
6. **Performance Optimization:** Strategic index creation for large datasets
7. **Error Handling:** Function-level error handling with proper return codes
8. **Code Quality:** Clean, comment-free scripts with clear structure
9. **Cross-Platform Development:** Environment variable usage for path flexibility

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

1. **Function-Based Architecture**: Organize code into reusable, single-purpose functions
2. **Clean Code Principles**: Write clear, comment-free code that's self-documenting
3. **Performance Optimization**: Create strategic indexes for large datasets
4. **Error Handling**: Use proper return codes and clear error messages
5. **Environment Configuration**: Use variables for flexible deployment
6. **Data Validation**: Always check if data already exists before loading

---

*Part of the 42 Data Science Piscine curriculum*
