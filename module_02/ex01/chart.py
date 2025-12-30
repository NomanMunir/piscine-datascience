import matplotlib
import matplotlib.pyplot as plt
import pandas as pd
import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import matplotlib.dates as mdates
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


def get_data():
    """Connect to database and extract purchase data for analysis"""
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
    engine = create_engine(connection_string)

    try:
        query = """
        SELECT event_time, price, user_id
        FROM customers 
        WHERE event_type = 'purchase'
            AND event_time >= '2022-10-01'
            AND event_time < '2023-02-28'
        """

        data = pd.read_sql_query(query, engine)

        data["event_time"] = pd.to_datetime(data["event_time"])
        data["date"] = data["event_time"].dt.date
        data["month"] = data["event_time"].dt.to_period("M")

        return data
    finally:
        engine.dispose()


def chart1_customers_per_day(data):
    """Create Chart 1: Number of unique customers per day"""
    daily_customers = data.groupby("date")["user_id"].nunique().reset_index()
    daily_customers.columns = ["date", "customers"]

    plt.figure(figsize=(10, 6))
    plt.plot(
        daily_customers["date"],
        daily_customers["customers"],
        color="#5F9BD1",
        linewidth=1.5,
    )
    plt.fill_between(
        daily_customers["date"],
        daily_customers["customers"],
        alpha=0.4,
        color="#7FB3D3",
    )

    plt.gca().xaxis.set_major_locator(mdates.MonthLocator())
    plt.gca().xaxis.set_major_formatter(mdates.DateFormatter("%b"))

    plt.title("Number of Customers per Day", fontsize=14, fontweight="bold")
    plt.ylabel("number of customers")
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.show(block=False)
    try:
        input("Press Enter for Chart 2...")
    except (KeyboardInterrupt, EOFError):
        pass
    finally:
        plt.close()


def chart2_sales_by_month(data):
    """Create Chart 2: Total sales by month in millions"""
    monthly_sales = data.groupby("month")["price"].sum().reset_index()
    monthly_sales["sales_millions"] = monthly_sales["price"] / 1_000_000

    # Extract month names from the data dynamically
    month_labels = [month.strftime("%b") for month in monthly_sales["month"]]

    plt.figure(figsize=(10, 6))
    plt.bar(month_labels, monthly_sales["sales_millions"], color="#7FB3D3", alpha=0.8)

    plt.title("Total Sales by Month", fontsize=14, fontweight="bold")
    plt.xlabel("Month")
    plt.ylabel("total sales in million of ₳")
    plt.grid(True, alpha=0.3, axis="y")
    plt.tight_layout()
    plt.show(block=False)
    try:
        input("Press Enter for Chart 3...")
    except (KeyboardInterrupt, EOFError):
        pass
    finally:
        plt.close()


def chart3_avg_spend_per_day(data):
    """Create Chart 3: Average spend per customer per day"""
    daily_data = (
        data.groupby("date").agg({"price": "sum", "user_id": "nunique"}).reset_index()
    )
    daily_data["avg_spend"] = daily_data["price"] / daily_data["user_id"]

    plt.figure(figsize=(10, 6))
    plt.plot(
        daily_data["date"], daily_data["avg_spend"], color="#5F9BD1", linewidth=1.5
    )
    plt.fill_between(
        daily_data["date"], daily_data["avg_spend"], alpha=0.4, color="#7FB3D3"
    )

    plt.gca().xaxis.set_major_locator(mdates.MonthLocator())
    plt.gca().xaxis.set_major_formatter(mdates.DateFormatter("%b"))

    plt.title("Average Spend per Customer per Day", fontsize=14, fontweight="bold")
    plt.ylabel("average spend/customers in ₳")
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.show(block=False)
    try:
        input("Press Enter to exit...")
    except (KeyboardInterrupt, EOFError):
        pass
    finally:
        plt.close()


def main():
    """Main function to execute chart creation process"""
    print("Loading purchase data...")
    data = get_data()

    if data.empty:
        print("\nNo purchase data available for the specified period.")
        return

    print(f"Found {len(data):,} purchases")
    print(f"Total sales: ₳{data['price'].sum():,.2f}")

    chart1_customers_per_day(data)
    chart2_sales_by_month(data)
    chart3_avg_spend_per_day(data)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
