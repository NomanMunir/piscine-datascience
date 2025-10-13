"""Bar charts for order frequency and customer spending analysis."""

import matplotlib
import matplotlib.pyplot as plt
import pandas as pd
import os
from pathlib import Path
from dotenv import load_dotenv
from sqlalchemy import create_engine

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

def get_db_engine():
    """Establish PostgreSQL database engine using environment variables."""
    db_host = os.getenv('POSTGRES_HOST', 'localhost')
    db_port = os.getenv('POSTGRES_PORT', '5432')
    db_name = os.getenv('POSTGRES_DB')
    db_user = os.getenv('POSTGRES_USER')
    db_password = os.getenv('POSTGRES_PASSWORD')
    
    connection_string = f"postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
    return create_engine(connection_string)

def extract_order_data():
    """Extract purchase data for order frequency analysis."""
    engine = get_db_engine()
    
    query = """
    SELECT user_id, price
    FROM customers 
    WHERE event_type = 'purchase'
        AND price IS NOT NULL
    """
    
    data = pd.read_sql_query(query, engine)
    engine.dispose()
    return data

def create_frequency_chart(data):
    """Create bar chart showing number of orders by frequency."""
    orders_per_customer = data.groupby('user_id').size().reset_index(name='order_count')
    
    bins = [0, 10, 20, 30, 40, float('inf')]
    labels = ['0-10', '10-20', '20-30', '30-40', '40+']
    orders_per_customer['frequency_range'] = pd.cut(orders_per_customer['order_count'], 
                                                   bins=bins, labels=labels, right=False)
    
    frequency_counts = orders_per_customer['frequency_range'].value_counts().sort_index()
    
    fig, ax = plt.subplots(figsize=(10, 6))
    
    ax.bar(range(len(frequency_counts)), frequency_counts.values, 
           color='lightblue', alpha=0.8)
    
    ax.set_xlabel('frequency')
    ax.set_ylabel('customers')
    ax.set_title('Number of Orders According to Frequency', 
                 fontsize=14, fontweight='bold')
    ax.set_xticks(range(len(labels)))
    ax.set_xticklabels(['0', '10', '20', '30', '40'])
    ax.grid(True, alpha=0.3, axis='y')
    plt.tight_layout()
    return fig

def create_spending_chart(data):
    """Create bar chart showing Altairian Dollars spent by customers."""
    customer_spending = data.groupby('user_id')['price'].sum().reset_index()
    customer_spending.columns = ['user_id', 'total_spent']
    
    bins = [0, 50, 100, 150, 200, float('inf')]
    labels = ['0-50', '50-100', '100-150', '150-200', '200+']
    customer_spending['spending_range'] = pd.cut(customer_spending['total_spent'], 
                                               bins=bins, labels=labels, right=False)
    
    spending_counts = customer_spending['spending_range'].value_counts().sort_index()
    
    fig, ax = plt.subplots(figsize=(10, 6))
    
    ax.bar(range(len(spending_counts)), spending_counts.values, 
           color='lightblue', alpha=0.8)
    
    ax.set_xlabel('monetary value in ₳')
    ax.set_ylabel('customers')
    ax.set_title('Altairian Dollars Spent on the Site by Customers', 
                 fontsize=14, fontweight='bold')
    ax.set_xticks(range(len(labels)))
    ax.set_xticklabels(['0', '50', '100', '150', '200'])
    ax.grid(True, alpha=0.3, axis='y')
    plt.tight_layout()
    return fig

def main():
    """Main function to execute order frequency and spending analysis."""
    try:
        print("Connecting to database and extracting order data...")
        data = extract_order_data()
        
        if data.empty:
            print("No order data found.")
            return
        
        print(f"Found {len(data):,} purchase records")
        
        fig1 = create_frequency_chart(data)
        plt.show()
        input("Press Enter for next chart...")
        plt.close(fig1)
        
        fig2 = create_spending_chart(data)
        plt.show()
        input("Press Enter to exit...")
        plt.close(fig2)
        
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    main()
