# Piscine Data Science

A comprehensive data science project covering database creation, data warehousing, and data visualization.

## Project Overview

This project is structured as a series of modules, each focusing on different aspects of data science:

- **Module 00**: Database Creation and Basic Operations
- **Module 01**: Data Warehouse Development
- **Module 02**: Data Visualization

## Prerequisites

- **uv** - Python package manager (for dependency management)
- **Docker** - For running PostgreSQL database
- **Git** - Version control

## Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd piscine-datascience
   ```

2. **Initialize Python environment**
   ```bash
   uv init
   uv add matplotlib seaborn pandas psycopg2-binary jupyter
   ```

3. **Start with Module 00**
   ```bash
   cd module_00
   # Follow module-specific instructions
   ```

## Project Structure

```
piscine-datascience/
├── module_00/          # Database creation and basic operations
│   ├── data/           # Raw data files
│   ├── ex00/           # Docker setup
│   ├── ex01/           # Basic queries
│   ├── ex02/           # Table operations
│   ├── ex03/           # Automatic table creation
│   └── ex04/           # Items table
├── module_01/          # Data warehouse development
│   ├── data/           # Customer and item data
│   ├── ex00/           # Environment setup
│   ├── ex01/           # Customer table creation
│   ├── ex02/           # Data cleaning
│   └── ex03/           # Data fusion
├── module_02/          # Data visualization
│   └── ex00/           # Pie chart visualization
├── subjects/           # Project documentation
└── pyproject.toml      # Python dependencies
```

## Dependencies

The project uses the following Python packages (managed by uv):

- **pandas** - Data manipulation and analysis
- **matplotlib** - Plotting and visualization
- **seaborn** - Statistical data visualization
- **psycopg2-binary** - PostgreSQL adapter
- **jupyter** - Interactive notebooks

## Database Setup

The project uses PostgreSQL running in Docker. Database credentials are managed through environment variables in `module_01/.env`.

## Running the Project

Each module can be run independently, but they build upon each other:

1. **Module 00**: Sets up the database infrastructure
2. **Module 01**: Creates and populates the data warehouse
3. **Module 02**: Visualizes the data from the warehouse

### Using uv

To run any Python script or notebook:

```bash
# Run a Python script
uv run module_02/ex00/pie.py

# Start Jupyter notebook
uv run jupyter notebook

# Activate virtual environment
source .venv/bin/activate  # Unix/macOS
.venv\Scripts\activate     # Windows
```

## Contributing

1. Follow the module structure for new exercises
2. Use meaningful commit messages
3. Document any new dependencies in `pyproject.toml`
4. Include README updates for new modules

## License

This project is part of the Piscine Data Science curriculum.

## Contact

- Repository: [piscine-datascience](https://github.com/NomanMunir/piscine-datascience)
- Author: NomanMunir
