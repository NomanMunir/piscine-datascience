# Module 00 - Database Creation and Management

This module covers the fundamentals of database creation, table management, and data loading using PostgreSQL and Docker.

## Overview

Module 00 introduces data science students to database concepts through hands-on exercises using PostgreSQL, pgAdmin, and Docker Compose. Each exercise builds upon the previous one, progressing from basic database setup to automated table creation.

## Prerequisites

- Docker and Docker Compose installed
- Basic understanding of SQL
- Command line familiarity

## Exercises

### Exercise 00 - Basic PostgreSQL Setup
**Directory:** `ex00/`  
**Objective:** Set up a basic PostgreSQL database with Docker Compose  
**Key Files:** `docker-compose.yml`, `.env`  
**What you'll learn:** Docker containerization, PostgreSQL basics, environment configuration

### Exercise 01 - Database Visualization
**Directory:** `ex01/`  
**Objective:** Add pgAdmin for database administration and visualization  
**Key Files:** `docker-compose.yml`, `.env`  
**What you'll learn:** Database administration tools, web-based interfaces, container networking

### Exercise 02 - Manual Table Creation
**Directory:** `ex02/`  
**Objective:** Create tables with specific data types and load CSV data  
**Key Files:** `table.sql`, `entrypoint.sh`  
**What you'll learn:** SQL data types, table creation, CSV data loading, PostgreSQL functions

### Exercise 03 - Automatic Table Creation
**Directory:** `ex03/`  
**Objective:** Automatically create tables for all CSV files in a directory  
**Key Files:** `automatic_table.sql`, `entrypoint.sh`  
**What you'll learn:** Dynamic SQL, shell scripting, file system operations, automation

### Exercise 04 - Items Table Creation
**Directory:** `ex04/`  
**Objective:** Create an `items` table from item.csv with multiple data types  
**Key Files:** `items_table.sql`, `entrypoint.sh`  
**What you'll learn:** Schema design, data type selection, NULL handling, specific table requirements

## Data Structure

The module uses e-commerce data stored in CSV format:
- **Customer data:** Transaction records with timestamps, events, products, prices, and user sessions
- **Item data:** Product catalog with categories, brands, and identifiers

## Common Commands

### Starting an Exercise
```bash
cd module_00/ex##
docker compose up -d
```

### Viewing Logs
```bash
docker logs piscineds_postgres
```

### Accessing pgAdmin
- URL: http://localhost:8080
- Email: admin@piscineds.com
- Password: admin123

### Stopping Services
```bash
docker compose down -v
```

## Database Schema

### Customer Tables (ex02, ex03)
- `event_time`: TIMESTAMP WITH TIME ZONE
- `event_type`: VARCHAR(50)
- `product_id`: BIGINT
- `price`: NUMERIC(10,2)
- `user_id`: BIGINT
- `user_session`: UUID

### Items Table (ex04)
- `product_id`: BIGINT (NOT NULL)
- `category_id`: BIGINT (nullable)
- `category_code`: VARCHAR(255) (nullable)
- `brand`: TEXT (nullable)

## Key Learning Outcomes

1. **Docker Containerization:** Understanding how to use Docker Compose for database services
2. **PostgreSQL Administration:** Managing databases, users, and connections
3. **SQL Data Types:** Working with various PostgreSQL data types (BIGINT, VARCHAR, TEXT, UUID, TIMESTAMP, NUMERIC)
4. **Data Loading:** Using COPY commands to efficiently load CSV data
5. **Automation:** Creating scripts for dynamic table creation and data processing
6. **Error Handling:** Managing NULL values and data type constraints

## Troubleshooting

### Common Issues

1. **Port Conflicts:** Ensure ports 5432 and 8080 are available
2. **Volume Permissions:** Use `docker compose down -v` to reset volumes if needed
3. **NULL Constraints:** Check CSV data for empty values when designing table schemas
4. **File Paths:** Ensure CSV files are properly mounted in Docker containers

### Useful Commands

```bash
# Check running containers
docker ps

# View container logs
docker logs [container_name]

# Connect to PostgreSQL directly
docker exec -it piscineds_postgres psql -U nmunir -d piscineds

# Reset everything
docker compose down -v && docker compose up -d
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
