# Module 01 - Data Warehouse Development

This module focuses on building a comprehensive data warehouse by creating, cleaning, and merging customer and item data tables.

## Overview

Module 01 transforms raw e-commerce data into a structured data warehouse. Students learn data cleaning techniques, table relationships, and data fusion operations essential for analytics and business intelligence.

## Learning Objectives

- Set up a PostgreSQL environment for data warehousing
- Create and manage customer data tables from multiple CSV files
- Implement data cleaning and deduplication strategies
- Perform data fusion operations between customer and item tables
- Understand table relationships and foreign key constraints

## Prerequisites

- Completed Module 00 (basic database operations)
- Docker and Docker Compose
- Basic SQL knowledge
- Understanding of CSV data formats

## Environment Setup

This module uses a dedicated `.env` file for database configuration:

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

## Data Structure

The module works with two main data types:

### Customer Data
- Multiple CSV files by month (2022 Oct-Dec, 2023 Jan)
- Contains user behavior: views, cart additions, purchases, removals
- Event timestamps and user identifiers
- Price and product information

### Item Data
- Product catalog with category information
- Brand and category mappings
- Product metadata

## Exercises

### Exercise 00: Environment Setup
**File**: `ex00/` (setup files)
- Configure PostgreSQL environment
- Set up database connections
- Verify data file accessibility

### Exercise 01: Customer Table Creation
**File**: `ex01/customers_table.sh`
- Create customers table from multiple CSV files
- Handle data type conversions
- Implement progress tracking and validation

**Key Features**:
- Automatic table creation with proper schema
- Multi-file data loading with progress indicators
- Data validation and error handling
- Performance optimization for large datasets

### Exercise 02: Data Cleaning
**File**: `ex02/remove_duplicates.sh`
- Identify and remove duplicate records
- Preserve data integrity during cleaning
- Generate cleaning reports

**Key Features**:
- Duplicate detection algorithms
- Safe duplicate removal procedures
- Data quality reporting
- Backup and recovery mechanisms

### Exercise 03: Data Fusion
**File**: `ex03/fusion.sh`
- Merge customer and item data tables
- Create enriched customer profiles
- Establish table relationships

**Key Features**:
- Intelligent data joining strategies
- Foreign key constraint management
- Performance-optimized fusion operations
- Data integrity validation

## Usage

### Running Individual Exercises

```bash
# Navigate to module directory
cd module_01

# Exercise 01: Create customer tables
./ex01/customers_table.sh

# Exercise 02: Clean data
./ex02/remove_duplicates.sh

# Exercise 03: Merge data
./ex03/fusion.sh
```

### Complete Pipeline

```bash
# Run all exercises in sequence
cd module_01
./ex01/customers_table.sh && ./ex02/remove_duplicates.sh && ./ex03/fusion.sh
```

## Database Schema

After completion, the data warehouse contains:

- **customers**: Main customer behavior table with item details
- **items**: Product catalog with categories and brands
- **data_***: Monthly raw data tables (archived)

## Key Achievements

1. **Scalable Data Processing**: Handles millions of records efficiently
2. **Data Quality**: Implements comprehensive cleaning and validation
3. **Performance**: Optimized for large-scale data operations
4. **Reliability**: Robust error handling and recovery mechanisms
5. **Documentation**: Clear progress tracking and reporting

## Results

The completed data warehouse provides:
- Clean, deduplicated customer behavior data
- Enriched product information
- Optimized structure for analytics
- Foundation for Module 02 visualizations

## Next Steps

Module 01 data warehouse serves as the foundation for Module 02 data visualization exercises.

## Troubleshooting

### Common Issues

1. **Database Connection**: Ensure PostgreSQL container is running
2. **File Permissions**: Check CSV file accessibility
3. **Memory Issues**: Monitor system resources during large data loads
4. **Data Integrity**: Verify table constraints and relationships

### Performance Tips

- Use appropriate indexes for large tables
- Monitor disk space during operations
- Consider partitioning for very large datasets
- Implement batch processing for memory efficiency

## Dependencies

- PostgreSQL 16+
- Docker and Docker Compose
- Bash shell environment
- CSV data files in specified format