# Module 02 - Data Visualization

This module focuses on creating data visualizations, specifically pie charts to analyze user behavior data from our Data Warehouse built in Module 01.

## Overview

Module 02 transforms the data warehouse from Module 01 into meaningful visual insights. Students learn to connect to databases, extract behavioral data, and create professional-quality visualizations that tell compelling stories about user engagement and conversion patterns.

## Learning Objectives

- Connect Python applications to PostgreSQL databases
- Extract and analyze user behavior data
- Create professional pie chart visualizations
- Calculate and interpret key business metrics
- Present data insights through clear visual narratives

## Prerequisites

- Completed Module 01 (Data Warehouse)
- Python 3.10+ with uv package manager
- Running PostgreSQL database from Module 01
- Basic understanding of data analysis concepts

## Exercise 00: American Apple Pie

**File**: `ex00/pie.ipynb`
**Goal**: Create pie charts to visualize user behavior distribution

### What You'll Build

A comprehensive Jupyter notebook that:
- Connects to the Module 01 data warehouse
- Extracts user behavior data (view, cart, purchase, remove_from_cart)
- Generates beautiful pie chart visualizations
- Calculates key business metrics and conversion rates

### Key Features

🥧 **Visual Appeal**: Professional pie charts with custom colors and styling
📊 **Business Insights**: Automatic calculation of conversion rates and metrics
🔍 **Data Analysis**: Clear breakdown of user behavior patterns
📈 **Interactive**: Jupyter notebook format for exploration and experimentation

## Technical Implementation

### Data Connection
- Connects to PostgreSQL using psycopg2
- Reads environment configuration from Module 01
- Handles database errors gracefully

### Visualization
- Uses matplotlib for high-quality charts
- Custom color scheme for different user actions
- Professional formatting and legends

### Metrics Calculated
- **View-to-Cart Rate**: Percentage of views that result in cart additions
- **Cart-to-Purchase Rate**: Percentage of cart additions that convert to purchases
- **Overall Conversion Rate**: Percentage of views that result in purchases
- **Action Distribution**: Breakdown of all user behaviors

## Requirements
- Python 3.10+ (managed by uv)
- matplotlib/seaborn for visualization
- pandas for data manipulation
- psycopg2 for PostgreSQL connectivity
- jupyter for interactive notebooks

## Setup
The project uses `uv` for Python package management. All dependencies are already installed in the parent directory.

```bash
# Activate the virtual environment
uv run <script_name>
# or
source .venv/Scripts/activate  # Windows
source .venv/bin/activate      # Unix/macOS
```

## Usage

### Running the Notebook

```bash
# From the root directory
uv run jupyter notebook module_02/ex00/pie.ipynb

# Or navigate to the exercise directory
cd module_02/ex00
uv run jupyter notebook pie.ipynb
```

### Expected Output

The notebook will generate:
1. **Connection Status**: Confirmation of database connectivity
2. **Data Summary**: Overview of extracted user behavior data
3. **Pie Chart**: Visual representation of user action distribution
4. **Business Metrics**: Key conversion rates and insights

### Sample Results

Based on the data warehouse:
- **Total Events**: ~16.5 million user interactions
- **View-to-Cart Rate**: ~60% (excellent engagement)
- **Cart-to-Purchase Rate**: ~23% (good conversion)
- **Overall Conversion Rate**: ~14% (healthy funnel)

## Data Schema

The visualization connects to these tables from Module 01:
- **customers**: Main table with user behavior events
- **items**: Product information (for potential future enhancements)

### Key Fields Used
- `event_type`: User action (view, cart, purchase, remove_from_cart)
- Count aggregations for each event type

## Troubleshooting

### Common Issues

1. **Database Connection Error**
   ```
   Solution: Ensure PostgreSQL container from Module 01 is running
   Check: docker ps | grep postgres
   ```

2. **No Data Found**
   ```
   Solution: Verify Module 01 data warehouse was successfully created
   Check: Run Module 01 fusion script if needed
   ```

3. **Import Errors**
   ```
   Solution: Ensure all dependencies are installed
   Run: uv add matplotlib seaborn pandas psycopg2-binary jupyter
   ```

## File Structure

```
module_02/
├── README.md           # This documentation
└── ex00/
    └── pie.ipynb       # Main visualization notebook
```

## Next Steps

This module completes the data science pipeline:
1. **Module 00**: Database infrastructure ✅
2. **Module 01**: Data warehouse creation ✅
3. **Module 02**: Data visualization ✅

The pie chart visualizations provide actionable insights for:
- **Marketing Teams**: Understanding user engagement patterns
- **Product Teams**: Identifying conversion bottlenecks
- **Business Teams**: Measuring funnel performance
- **Data Teams**: Baseline metrics for optimization

## Best Practices Demonstrated

- **Clean Code**: Well-documented, readable notebook structure
- **Error Handling**: Graceful database connection management
- **Professional Visualization**: Industry-standard chart formatting
- **Business Focus**: Metrics that matter to stakeholders
- **Reproducibility**: Clear setup and execution instructions