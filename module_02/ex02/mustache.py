"""Statistical analysis and box plot visualization of purchase prices."""

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
    """Establish PostgreSQL database connection using environment variables."""
    return psycopg2.connect(
        host=os.getenv('POSTGRES_HOST', 'localhost'),
        port=os.getenv('POSTGRES_PORT', '5432'),
        database=os.getenv('POSTGRES_DB'),
        user=os.getenv('POSTGRES_USER'),
        password=os.getenv('POSTGRES_PASSWORD')
    )

def extract_purchase_data():
    """Extract purchase price data from the cleaned customers table."""
    conn = get_db_connection()
    
    query = """
    SELECT price, user_id
    FROM customers 
    WHERE event_type = 'purchase'
        AND price IS NOT NULL
    ORDER BY price;
    """
    
    data = pd.read_sql_query(query, conn)
    conn.close()
    return data

def calculate_statistics(data):
    """Calculate and display descriptive statistics for purchase prices."""
    prices = data['price']
    
    stats = {
        'count': len(prices),
        'mean': prices.mean(),
        'std': prices.std(),
        'min': prices.min(),
        '25%': prices.quantile(0.25),
        '50%': prices.quantile(0.50),
        '75%': prices.quantile(0.75),
        'max': prices.max()
    }
    
    print("Statistical Analysis of Purchase Prices:")
    print(f"count    {stats['count']:.6f}")
    print(f"mean     {stats['mean']:.6f}")
    print(f"std      {stats['std']:.6f}")
    print(f"min      {stats['min']:.6f}")
    print(f"25%      {stats['25%']:.6f}")
    print(f"50%      {stats['50%']:.6f}")
    print(f"75%      {stats['75%']:.6f}")
    print(f"max      {stats['max']:.6f}")
    
    return stats

def create_price_box_plot(data, zoom_to_main_range=False):
    """Create horizontal box plot for individual purchase price distribution."""
    fig, ax = plt.subplots(figsize=(10, 6))
    
    ax.boxplot(data['price'], 
               vert=False,
               patch_artist=True,
               boxprops=dict(facecolor='lightblue', alpha=0.7),
               medianprops=dict(color='red', linewidth=2))
    
    if zoom_to_main_range:
        q1 = data['price'].quantile(0.25)
        q3 = data['price'].quantile(0.75)
        iqr = q3 - q1
        lower_bound = q1 - 1.5 * iqr
        upper_bound = q3 + 1.5 * iqr
        ax.set_xlim(max(lower_bound, data['price'].min()), 
                    min(upper_bound, data['price'].quantile(0.95)))
    
    ax.set_xlabel('price')
    ax.set_title('Box Plot: Price Distribution of Purchased Items', 
                 fontsize=14, fontweight='bold')
    ax.grid(True, alpha=0.3)
    plt.tight_layout()
    return fig

def create_basket_box_plot(data):
    """Create horizontal box plot for average basket price per user."""
    user_avg_basket = data.groupby('user_id')['price'].mean().reset_index()
    user_avg_basket.columns = ['user_id', 'avg_basket_price']
    
    fig, ax = plt.subplots(figsize=(10, 6))
    
    ax.boxplot(user_avg_basket['avg_basket_price'], 
               vert=False,
               patch_artist=True,
               boxprops=dict(facecolor='lightblue', alpha=0.7),
               medianprops=dict(color='red', linewidth=2))
    
    ax.set_xlabel('price')
    ax.set_title('Box Plot: Average Basket Price per User', 
                 fontsize=14, fontweight='bold')
    ax.grid(True, alpha=0.3)
    plt.tight_layout()
    return fig

def main():
    """Main function to execute statistical analysis and box plot visualizations."""
    try:
        print("Connecting to database and extracting purchase data...")
        data = extract_purchase_data()
        
        if data.empty:
            print("No purchase data found.")
            return
        
        print(f"Found {len(data):,} purchase records")
        print()
        
        calculate_statistics(data)
        print()
        
        fig1 = create_price_box_plot(data)
        plt.show()
        input("Press Enter for next chart...")
        plt.close(fig1)
        
        fig2 = create_basket_box_plot(data)
        plt.show()
        input("Press Enter to exit...")
        plt.close(fig2)
        
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    main()
