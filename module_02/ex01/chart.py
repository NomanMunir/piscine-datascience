import matplotlib
import matplotlib.pyplot as plt
import pandas as pd
import psycopg2
import os
from pathlib import Path
from dotenv import load_dotenv

try:
    matplotlib.use('Qt5Agg')
except ImportError:
    try:
        matplotlib.use('TkAgg')
    except ImportError:
        pass

plt.ion()

env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)

def get_db_connection():
    """Establish PostgreSQL database connection"""
    db_host = os.getenv('POSTGRES_HOST', 'localhost')
    db_port = os.getenv('POSTGRES_PORT', '5432')
    db_name = os.getenv('POSTGRES_DB')
    db_user = os.getenv('POSTGRES_USER')
    db_password = os.getenv('POSTGRES_PASSWORD')
    
    if not all([db_name, db_user, db_password]):
        raise ValueError("Missing required database credentials")
    
    return psycopg2.connect(
        host=db_host,
        port=db_port,
        database=db_name,
        user=db_user,
        password=db_password
    )

def extract_purchase_data():
    """Extract purchase data from October 2022 to February 2023"""
    conn = get_db_connection()
    
    query = """
    SELECT event_time, price, user_id
    FROM customers 
    WHERE event_type = 'purchase'
        AND event_time >= '2022-10-01'
        AND event_time < '2023-03-01'
    ORDER BY event_time;
    """
    
    data = pd.read_sql_query(query, conn)
    conn.close()
    
    data['event_time'] = pd.to_datetime(data['event_time'])
    data['month'] = data['event_time'].dt.to_period('M')
    
    return data

def prepare_daily_data(data):
    """Prepare daily aggregated data for charting"""
    data['date'] = data['event_time'].dt.date
    
    daily_data = data.groupby('date').agg({
        'user_id': 'nunique',
        'price': 'sum'
    }).reset_index()
    daily_data.columns = ['date', 'customer_count', 'total_sales']
    
    daily_data['avg_spend_per_customer'] = (daily_data['total_sales'] / daily_data['customer_count']).round(2)
    
    return daily_data

def prepare_monthly_data(data):
    """Prepare monthly aggregated data for charting"""
    customer_monthly_spend = data.groupby(['month', 'user_id'])['price'].sum().reset_index()
    
    monthly_data = data.groupby('month').agg({
        'price': 'sum',
        'user_id': 'nunique'
    }).reset_index()
    
    avg_spend_per_customer = customer_monthly_spend.groupby('month')['price'].mean()
    
    monthly_data.columns = ['month', 'total_sales', 'customer_count']
    monthly_data['avg_spend_per_customer'] = avg_spend_per_customer.values
    monthly_data = monthly_data.round(2)
    
    month_labels = ['Oct', 'Nov', 'Dec', 'Jan', 'Feb']
    monthly_data['month_str'] = month_labels[:len(monthly_data)]
    
    return monthly_data

def create_generic_chart(x_data, y_data, chart_type, title, xlabel='', ylabel='', color='#7FB3D3'):
    """Generic function to create different chart types"""
    fig, ax = plt.subplots(figsize=(10, 6))
    
    if chart_type == 'area':
        ax.fill_between(x_data, y_data, alpha=0.6, color=color)
        ax.plot(x_data, y_data, color='#5F9BD1', linewidth=2)
    elif chart_type == 'bar':
        ax.bar(x_data, y_data, color=color, alpha=0.8)
    elif chart_type == 'line':
        ax.plot(x_data, y_data, color='#5F9BD1', linewidth=2, marker='o', markersize=4)
        ax.fill_between(x_data, y_data, alpha=0.3, color=color)
    elif chart_type == 'line_daily':
        ax.plot(x_data, y_data, color='#5F9BD1', linewidth=1.5)
        ax.fill_between(x_data, y_data, alpha=0.4, color=color)
        import matplotlib.dates as mdates
        ax.xaxis.set_major_locator(mdates.MonthLocator())
        ax.xaxis.set_major_formatter(mdates.DateFormatter('%b'))
        ax.xaxis.set_minor_locator(mdates.WeekdayLocator())
    
    ax.set_title(title, fontsize=14, fontweight='bold')
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    ax.grid(True, alpha=0.3)
    ax.set_ylim(0, None)
    
    plt.tight_layout()
    return fig

def create_charts(data):
    """Create and display three charts sequentially"""
    daily_data = prepare_daily_data(data)
    monthly_data = prepare_monthly_data(data)
    
    print("Creating Chart 1: Number of Customers per Day...")
    fig1 = create_generic_chart(
        x_data=daily_data['date'],
        y_data=daily_data['customer_count'],
        chart_type='line_daily',
        title='Number of Customers per Day',
        ylabel='number of customers'
    )
    plt.show(block=False)
    input("Press Enter to continue to Chart 2...")
    plt.close(fig1)
    
    print("Creating Chart 2: Total Sales by Month...")
    total_sales_millions = monthly_data['total_sales'] / 1_000_000
    fig2 = create_generic_chart(
        x_data=monthly_data['month_str'],
        y_data=total_sales_millions,
        chart_type='bar',
        title='Total Sales by Month',
        xlabel='Month',
        ylabel='total sales in million (₳)'
    )
    plt.show(block=False)
    input("Press Enter to continue to Chart 3...")
    plt.close(fig2)
    
    print("Creating Chart 3: Average Spend per Customer per Day...")
    fig3 = create_generic_chart(
        x_data=daily_data['date'],
        y_data=daily_data['avg_spend_per_customer'],
        chart_type='line_daily',
        title='Average Spend per Customer per Day',
        ylabel='average spend/customer (₳)'
    )
    plt.show(block=False)
    input("Press Enter to exit...")
    plt.close(fig3)

def main():
    """Main function to execute chart creation process"""
    try:
        print("Connecting to database and extracting purchase data...")
        data = extract_purchase_data()
        
        if data.empty:
            print("No purchase data found for the specified period.")
            return
        
        print(f"Found {len(data):,} purchase records from October 2022 to February 2023")
        print(f"Total sales: ₳{data['price'].sum():,.2f}")
        print(f"Average purchase: ₳{data['price'].mean():.2f}")
        
        print("\nCreating charts...")
        create_charts(data)
        
    except Exception as e:
        print(f"Error: {e}")
        return
    except KeyboardInterrupt:
        print("\nProcess interrupted by user.")
        return

if __name__ == "__main__":
    main()
