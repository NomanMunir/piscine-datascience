"""Elbow Method for finding optimal number of customer clusters."""

import matplotlib.pyplot as plt
import pandas as pd
import os
from pathlib import Path
from dotenv import load_dotenv
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
import numpy as np
from sqlalchemy import create_engine

plt.ion()
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)


def get_db_engine():
    """Establish PostgreSQL database engine using environment variables."""
    db_host = os.getenv("POSTGRES_HOST", "localhost")
    db_port = os.getenv("POSTGRES_PORT", "5432")
    db_name = os.getenv("POSTGRES_DB")
    db_user = os.getenv("POSTGRES_USER")
    db_password = os.getenv("POSTGRES_PASSWORD")

    connection_string = (
        f"postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
    )
    return create_engine(connection_string)


def extract_customer_data():
    """Extract customer purchase data for clustering analysis."""
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


def prepare_clustering_features(data):
    """Prepare features for clustering: total spent and order frequency per customer."""
    customer_features = (
        data.groupby("user_id").agg({"price": ["sum", "count", "mean"]}).reset_index()
    )

    customer_features.columns = [
        "user_id",
        "total_spent",
        "order_count",
        "avg_order_value",
    ]

    features = customer_features[["total_spent", "order_count"]].copy()

    scaler = StandardScaler()
    features_scaled = scaler.fit_transform(features)

    return features_scaled, customer_features


def calculate_elbow_method(features, max_clusters=10):
    """Calculate inertia for different numbers of clusters."""
    inertias = []
    cluster_range = range(1, max_clusters + 1)

    for k in cluster_range:
        kmeans = KMeans(n_clusters=k, random_state=42, n_init=10)
        kmeans.fit(features)
        inertias.append(kmeans.inertia_)

    return cluster_range, inertias


def plot_elbow_method(cluster_range, inertias):
    """Create elbow method plot to determine optimal number of clusters."""
    fig, ax = plt.subplots(figsize=(10, 6))

    ax.plot(cluster_range, inertias, "bo-", linewidth=2, markersize=8)

    ax.set_xlabel("Number of clusters")
    ax.set_ylabel("Inertia")
    ax.set_title("The Elbow Method", fontsize=14, fontweight="bold")
    ax.grid(True, alpha=0.3)

    plt.tight_layout()
    return fig


def find_optimal_clusters(cluster_range, inertias):
    """Find the optimal number of clusters using elbow method analysis."""
    # Calculate the rate of change (differences between consecutive inertias)
    differences = np.diff(inertias)
    # Calculate the second derivative (rate of change of the rate of change)
    second_differences = np.diff(differences)

    # Find the elbow point (where the curve bends the most)
    elbow_point = np.argmax(second_differences) + 2  # +2 because of double diff

    return elbow_point


def main():
    """Main function to execute elbow method analysis."""
    try:
        print("Connecting to database and extracting customer data...")
        data = extract_customer_data()

        if data.empty:
            print("No customer data found.")
            return

        print(f"Found {len(data):,} purchase records")

        print("Preparing clustering features...")
        features_scaled, customer_features = prepare_clustering_features(data)

        print(f"Analyzing {len(customer_features):,} unique customers")

        print("Calculating elbow method...")
        cluster_range, inertias = calculate_elbow_method(
            features_scaled, max_clusters=10
        )

        optimal_k = find_optimal_clusters(cluster_range, inertias)

        print(f"Suggested optimal number of clusters: {optimal_k}")
        print("\nElbow Method Analysis:")
        print("- The elbow point indicates where adding more clusters")
        print("  provides diminishing returns in reducing inertia")
        print(
            "- Look for the 'bend' in the curve where the slope changes significantly"
        )

        fig = plot_elbow_method(cluster_range, inertias)
        plt.show()
        try:
            input("Press Enter to exit...")
        except KeyboardInterrupt:
            print("\n\nProgram interrupted by user. Exiting gracefully...")
        finally:
            plt.close(fig)

    except KeyboardInterrupt:
        print("\n\nProgram interrupted by user. Exiting gracefully...")
        plt.close('all')
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    main()
