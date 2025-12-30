"""Bar charts for order frequency and customer spending analysis."""

import matplotlib
import matplotlib.pyplot as plt
import pandas as pd
import os
import sys
from pathlib import Path
from dotenv import load_dotenv
from sqlalchemy import create_engine

backend_set = False
for backend in ["TkAgg", "Qt5Agg"]:
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
env_path = Path(__file__).parent.parent.parent / ".env"
load_dotenv(env_path)


def get_db_engine():
    """Establish PostgreSQL database engine using environment variables."""
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


def extract_order_data():
    """Extract purchase data for order frequency analysis."""
    engine = get_db_engine()

    try:
        query = """
        SELECT user_id, price
        FROM customers 

        WHERE event_type = 'purchase'
            AND price IS NOT NULL
            AND price > 0
        """

        data = pd.read_sql_query(query, engine)
        return data
    finally:
        engine.dispose()


def create_frequency_chart(data):
    """Create bar chart showing number of orders by frequency."""
    orders_per_customer = data.groupby("user_id").size().reset_index(name="order_count")

    bins = [0, 10, 20, 30, 40, float("inf")]
    labels = ["0-10", "10-20", "20-30", "30-40", "40+"]
    orders_per_customer["frequency_range"] = pd.cut(
        orders_per_customer["order_count"], bins=bins, labels=labels, right=False
    )

    frequency_counts = (
        orders_per_customer["frequency_range"].value_counts().sort_index()
    )

    fig, ax = plt.subplots(figsize=(10, 6))

    x_positions = [0, 10, 20, 30, 40]
    bar_width = 8

    ax.bar(
        x_positions,
        frequency_counts.values,
        width=bar_width,
        color="#A8C5DD",
        alpha=0.9,
        edgecolor="none",
    )

    ax.set_xlabel("frequency")
    ax.set_ylabel("customers")
    ax.set_title(
        "Number of Orders According to Frequency", fontsize=14, fontweight="bold"
    )
    ax.set_xticks(x_positions)
    ax.set_xticklabels(["0", "10", "20", "30", "40"])
    ax.set_xlim(-5, 45)
    ax.grid(True, alpha=0.3, axis="y")
    plt.tight_layout()
    return fig


def create_spending_chart(data):
    """Create bar chart showing Altairian Dollars spent by customers."""
    customer_spending = data.groupby("user_id")["price"].sum().reset_index()
    customer_spending.columns = ["user_id", "total_spent"]

    bins = [0, 50, 100, 150, 200, float("inf")]
    labels = ["0-50", "50-100", "100-150", "150-200", "200+"]
    customer_spending["spending_range"] = pd.cut(
        customer_spending["total_spent"], bins=bins, labels=labels, right=False
    )

    spending_counts = customer_spending["spending_range"].value_counts().sort_index()

    fig, ax = plt.subplots(figsize=(10, 6))

    x_positions = [0, 50, 100, 150, 200]
    bar_width = 40

    ax.bar(
        x_positions,
        spending_counts.values,
        width=bar_width,
        color="#A8C5DD",
        alpha=0.9,
        edgecolor="none",
    )

    ax.set_xlabel("monetary value in ₳")
    ax.set_ylabel("customers")
    ax.set_title(
        "Altairian Dollars Spent on the Site by Customers",
        fontsize=14,
        fontweight="bold",
    )
    ax.set_xticks(x_positions)
    ax.set_xticklabels(["0", "50", "100", "150", "200"])
    ax.set_xlim(-25, 225)
    ax.grid(True, alpha=0.3, axis="y")
    plt.tight_layout()
    return fig


def main():
    """Main function to execute order frequency and spending analysis."""
    print("Connecting to database and extracting order data...")
    data = extract_order_data()

    if data.empty:
        print("No order data found.")
        return

    print(f"Found {len(data):,} purchase records")

    fig1 = create_frequency_chart(data)
    plt.show()
    try:
        input("Press Enter for next chart...")
    except (KeyboardInterrupt, EOFError):
        pass
    finally:
        plt.close(fig1)

    fig2 = create_spending_chart(data)
    plt.show()
    try:
        input("Press Enter to exit...")
    except (KeyboardInterrupt, EOFError):
        pass
    finally:
        plt.close(fig2)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
