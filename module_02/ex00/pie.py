import matplotlib
import matplotlib.pyplot as plt
import pandas as pd
import os
import sys
from pathlib import Path
from dotenv import load_dotenv
from sqlalchemy import create_engine

backend_set = False
for backend in ["Qt5Agg", "TkAgg"]:
    try:
        matplotlib.use(backend)
        backend_set = True
        break
    except ImportError:
        continue

if not backend_set:
    print("Warning: No GUI backend available. Using non-interactive 'Agg' backend.", file=sys.stderr)
    matplotlib.use("Agg")

plt.ion()

env_path = Path("../../.env")
load_dotenv(env_path)


def get_db_engine():
    db_host = os.getenv("POSTGRES_HOST", "localhost")
    db_port = os.getenv("POSTGRES_PORT", "5432")
    db_name = os.getenv("POSTGRES_DB")
    db_user = os.getenv("POSTGRES_USER")
    db_password = os.getenv("POSTGRES_PASSWORD")

    if not all([db_name, db_user, db_password]):
        raise ValueError("Missing required database credentials")

    connection_string = (
        f"postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
    )
    return create_engine(connection_string)


def main():
    engine = get_db_engine()

    try:
        query = """
        SELECT 
            COALESCE(event_type, 'unknown') as action,
            COUNT(*) as count
        FROM customers 
        GROUP BY event_type
        ORDER BY count DESC;
        """

        data = pd.read_sql_query(query, engine)

        print("User behavior data:")
        print(data)
        print(f"Total events: {data['count'].sum():,}")
    finally:
        engine.dispose()

    # Check for empty data
    if data.empty:
        print("\nNo data available to plot.")
        return

    fig, ax = plt.subplots(figsize=(12, 10))
    
    # Generate colors and explode values dynamically based on data length
    num_categories = len(data)
    colors = plt.cm.Set3(range(num_categories))
    explode = [0.05] * num_categories

    ax.pie(
        data["count"],
        labels=data["action"],
        colors=colors,
        autopct="%1.1f%%",
        startangle=90,
        explode=explode,
    )

    ax.set_title("Pie Chart", fontsize=18, fontweight="bold")
    ax.axis("equal")

    plt.show(block=False)
    try:
        input("Press Enter to exit...")
    except (KeyboardInterrupt, EOFError):
        print("\n\nProgram interrupted. Exiting gracefully...")
    finally:
        plt.close(fig)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
