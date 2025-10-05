import matplotlib.pyplot as plt
import pandas as pd
import psycopg2
import os
from pathlib import Path
from dotenv import load_dotenv
import matplotlib.dates as mdates

plt.ion()
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)

def get_data():
    """Connect to database and extract purchase data for analysis"""
    conn = psycopg2.connect(
        host=os.getenv('POSTGRES_HOST', 'localhost'),
        port=os.getenv('POSTGRES_PORT', '5432'),
        database=os.getenv('POSTGRES_DB'),
        user=os.getenv('POSTGRES_USER'),
        password=os.getenv('POSTGRES_PASSWORD')
    )
    
    query = """
    SELECT event_time, price, user_id
    FROM customers 
    WHERE event_type = 'purchase'
        AND event_time >= '2022-10-01'
        AND event_time < '2023-02-28'
    """
    
    data = pd.read_sql_query(query, conn)
    conn.close()
    
    data['event_time'] = pd.to_datetime(data['event_time'])
    data['date'] = data['event_time'].dt.date
    data['month'] = data['event_time'].dt.to_period('M')
    
    return data

def chart1_customers_per_day(data):
    """Create Chart 1: Number of unique customers per day"""
    daily_customers = data.groupby('date')['user_id'].nunique().reset_index()
    daily_customers.columns = ['date', 'customers']
    
    plt.figure(figsize=(10, 6))
    plt.plot(daily_customers['date'], daily_customers['customers'], color='#5F9BD1', linewidth=1.5)
    plt.fill_between(daily_customers['date'], daily_customers['customers'], alpha=0.4, color='#7FB3D3')
    
    plt.gca().xaxis.set_major_locator(mdates.MonthLocator())
    plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%b'))
    
    plt.title('Number of Customers per Day', fontsize=14, fontweight='bold')
    plt.ylabel('number of customers')
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.show(block=False)
    input("Press Enter for Chart 2...")
    plt.close()

def chart2_sales_by_month(data):
    """Create Chart 2: Total sales by month in millions"""
    monthly_sales = data.groupby('month')['price'].sum().reset_index()
    monthly_sales['sales_millions'] = monthly_sales['price'] / 1_000_000
    
    # Extract month names from the data dynamically
    month_labels = [month.strftime('%b') for month in monthly_sales['month']]
    
    plt.figure(figsize=(10, 6))
    plt.bar(month_labels, monthly_sales['sales_millions'], 
            color='#7FB3D3', alpha=0.8)
    
    plt.title('Total Sales by Month', fontsize=14, fontweight='bold')
    plt.xlabel('Month')
    plt.ylabel('total sales in million of ₳')
    plt.grid(True, alpha=0.3, axis='y')
    plt.tight_layout()
    plt.show(block=False)
    input("Press Enter for Chart 3...")
    plt.close()

def chart3_avg_spend_per_day(data):
    """Create Chart 3: Average spend per customer per day"""
    daily_data = data.groupby('date').agg({
        'price': 'sum',
        'user_id': 'nunique'
    }).reset_index()
    daily_data['avg_spend'] = daily_data['price'] / daily_data['user_id']
    
    plt.figure(figsize=(10, 6))
    plt.plot(daily_data['date'], daily_data['avg_spend'], color='#5F9BD1', linewidth=1.5)
    plt.fill_between(daily_data['date'], daily_data['avg_spend'], alpha=0.4, color='#7FB3D3')
    
    plt.gca().xaxis.set_major_locator(mdates.MonthLocator())
    plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%b'))
    
    plt.title('Average Spend per Customer per Day', fontsize=14, fontweight='bold')
    plt.ylabel('average spend/customers in ₳')
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.show(block=False)
    input("Press Enter to exit...")
    plt.close()

def main():
    """Main function to execute chart creation process"""
    print("Loading purchase data...")
    data = get_data()
    
    print(f"Found {len(data):,} purchases")
    print(f"Total sales: ₳{data['price'].sum():,.2f}")
    
    chart1_customers_per_day(data)
    chart2_sales_by_month(data)
    chart3_avg_spend_per_day(data)

if __name__ == "__main__":
    main()
