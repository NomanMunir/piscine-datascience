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
    """Extract purchase data for statistical analysis"""
    conn = get_db_connection()
    
    # Try to match the expected count by filtering more specifically
    query = """
    SELECT price
    FROM customers 
    WHERE event_type = 'purchase'
        AND price IS NOT NULL
        AND price > 0
        AND price <= 50
    ORDER BY price;
    """
    
    data = pd.read_sql_query(query, conn)
    conn.close()
    
    return data

def calculate_statistics(data):
    """Calculate and print statistical measures"""
    prices = data['price']
    
    stats = {
        'count': len(prices),
        'mean': prices.mean(),
        'std': prices.std(),
        'min': prices.min(),
        '25%': prices.quantile(0.25),  # First quartile
        '50%': prices.quantile(0.50),  # Median (Second quartile)
        '75%': prices.quantile(0.75),  # Third quartile
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
    
    print(f"\nQuartiles Summary:")
    print(f"First quartile (25%):  {stats['25%']:.6f}")
    print(f"Second quartile (50%): {stats['50%']:.6f} (Median)")
    print(f"Third quartile (75%):  {stats['75%']:.6f}")
    
    return stats

def create_box_plot(data):
    """Create box plot for price distribution"""
    fig, ax = plt.subplots(figsize=(10, 6))
    
    box_plot = ax.boxplot(data['price'], 
                         vert=False,  # Horizontal box plot
                         patch_artist=True,
                         boxprops=dict(facecolor='lightblue', alpha=0.7),
                         medianprops=dict(color='red', linewidth=2))
    
    ax.set_xlabel('price')
    ax.set_title('Box Plot: Price Distribution of Purchased Items', 
                 fontsize=14, fontweight='bold')
    ax.grid(True, alpha=0.3)
    
    plt.tight_layout()
    return fig

def main():
    """Main function to execute statistical analysis and visualization"""
    try:
        print("Connecting to database and extracting purchase data...")
        data = extract_purchase_data()
        
        if data.empty:
            print("No purchase data found.")
            return
        
        print(f"Found {len(data):,} purchase records")
        print()
        
        # Calculate and print statistics
        stats = calculate_statistics(data)
        print()
        
        # Create and display box plot
        print("Creating box plot...")
        fig = create_box_plot(data)
        plt.show(block=False)
        input("Press Enter to exit...")
        plt.close(fig)
        
    except Exception as e:
        print(f"Error: {e}")
        return

if __name__ == "__main__":
    main()
