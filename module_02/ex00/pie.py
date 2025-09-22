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

env_path = Path("../.env")
load_dotenv(env_path)

def get_db_connection():
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

def main():
    conn = get_db_connection()
    
    query = """
    SELECT 
        COALESCE(event_type, 'unknown') as action,
        COUNT(*) as count
    FROM customers 
    GROUP BY event_type
    ORDER BY count DESC;
    """
    
    data = pd.read_sql_query(query, conn)
    conn.close()
    
    print("User behavior data:")
    print(data)
    print(f"Total events: {data['count'].sum():,}")
    
    fig, ax = plt.subplots(figsize=(12, 10))
    colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#FFA07A']
    
    ax.pie(data['count'], 
           labels=data['action'],
           colors=colors,
           autopct='%1.1f%%',
           startangle=90,
           explode=(0.05, 0.05, 0.05, 0.05))
    
    ax.set_title('Pie Chart', fontsize=18, fontweight='bold')
    ax.axis('equal')
    
    plt.show(block=False)
    input("Press Enter to exit...")

if __name__ == "__main__":
    main()