#!/usr/bin/env python3

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
import os
from pathlib import Path
from dotenv import load_dotenv
from sqlalchemy import create_engine

plt.ion()
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)


def get_db_engine():
    """Connect to PostgreSQL database using environment variables"""
    try:
        db_host = os.getenv("POSTGRES_HOST", "localhost")
        db_port = os.getenv("POSTGRES_PORT", "5432")
        db_name = os.getenv("POSTGRES_DB")
        db_user = os.getenv("POSTGRES_USER")
        db_password = os.getenv("POSTGRES_PASSWORD")

        connection_string = (
            f"postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
        )
        return create_engine(connection_string)
    except Exception as e:
        print(f"Error connecting to database: {e}")
        return None


def extract_customer_features():
    """Extract customer behavioral features for clustering"""
    engine = get_db_engine()
    if not engine:
        return None

    print("Extracting customer behavioral features...")

    # Simplified query to get comprehensive customer metrics
    query = """
    SELECT 
        user_id as customer_id,
        COUNT(*) as total_purchases,
        SUM(price) as total_spent,
        AVG(price) as avg_purchase_value,
        MIN(event_time::date) as first_purchase_date,
        MAX(event_time::date) as last_purchase_date,
        (MAX(event_time::date) - MIN(event_time::date)) + 1 as customer_lifespan_days,
        COUNT(DISTINCT event_time::date) as active_days,
        (CURRENT_DATE - MAX(event_time::date)) as days_since_last_purchase
    FROM customers 
    WHERE price IS NOT NULL AND price > 0 AND event_type = 'purchase'
    GROUP BY user_id
    HAVING COUNT(*) > 0
    ORDER BY SUM(price) DESC;
    """

    try:
        data = pd.read_sql_query(query, engine)
        engine.dispose()

        # Calculate engagement rate and purchase intensity
        data["engagement_rate"] = data.apply(
            lambda x: (
                x["active_days"] / x["customer_lifespan_days"]
                if x["customer_lifespan_days"] > 0
                else 1
            ),
            axis=1,
        )
        data["purchase_intensity"] = data.apply(
            lambda x: (
                x["total_purchases"] / x["active_days"]
                if x["active_days"] > 0
                else x["total_purchases"]
            ),
            axis=1,
        )

        print(f"Extracted features for {len(data)} customers")
        return data
    except Exception as e:
        print(f"Error extracting data: {e}")
        if engine:
            engine.dispose()
        return None


def create_customer_segments(data):
    """Create customer segments using business rules and clustering"""

    # Create RFM-like features for clustering
    clustering_features = data[
        [
            "total_purchases",
            "total_spent",
            "avg_purchase_value",
            "days_since_last_purchase",
            "engagement_rate",
            "purchase_intensity",
        ]
    ].copy()

    # Handle any remaining NaN values
    clustering_features = clustering_features.fillna(0)

    # Scale features for clustering
    scaler = StandardScaler()
    scaled_features = scaler.fit_transform(clustering_features)

    # Apply K-means clustering with 6 clusters (to allow for business logic grouping)
    kmeans = KMeans(n_clusters=6, random_state=42, n_init=10)
    cluster_labels = kmeans.fit_predict(scaled_features)

    # Add cluster labels to original data
    data["cluster"] = cluster_labels

    # Create business-meaningful segments based on RFM analysis
    # Calculate percentiles for segmentation
    spending_high = data["total_spent"].quantile(0.8)
    spending_med = data["total_spent"].quantile(0.5)
    frequency_high = data["total_purchases"].quantile(0.8)
    frequency_med = data["total_purchases"].quantile(0.5)
    recency_recent = data["days_since_last_purchase"].quantile(0.2)
    recency_old = data["days_since_last_purchase"].quantile(0.8)

    def assign_customer_segment(row):
        spending = row["total_spent"]
        frequency = row["total_purchases"]
        recency = row["days_since_last_purchase"]

        # Platinum: High spending + High frequency + Recent activity
        if (
            spending >= spending_high
            and frequency >= frequency_high
            and recency <= recency_recent
        ):
            return "Platinum Customer"

        # Gold: High spending OR High frequency + Medium recency
        elif (
            spending >= spending_high or frequency >= frequency_high
        ) and recency <= recency_old:
            return "Gold Customer"

        # Silver: Medium spending + Medium frequency
        elif spending >= spending_med and frequency >= frequency_med:
            return "Silver Customer"

        # New customers: Low frequency but recent activity
        elif (
            frequency <= data["total_purchases"].quantile(0.3)
            and recency <= recency_recent
        ):
            return "New Customer"

        # Inactive: Old recency (haven't purchased in a while)
        elif recency >= recency_old:
            return "Inactive Customer"

        # Regular: Everyone else
        else:
            return "Regular Customer"

    data["customer_segment"] = data.apply(assign_customer_segment, axis=1)

    return data, kmeans, scaler


def create_four_key_visualizations(data):
    """Create 4 clean and comprehensive visualizations for customer segments"""

    # Define consistent color scheme
    segment_colors = {
        "New Customer": "#74C0FC",  # Light blue
        "Inactive Customer": "#51CF66",  # Green
        "Regular Customer": "#FFD43B",  # Yellow
        "Silver Customer": "#C0C0C0",  # Silver
        "Gold Customer": "#FFD700",  # Gold
        "Platinum Customer": "#E6E6FA",  # Light purple
    }

    # Chart 1: Customer Segment Distribution (Bar Chart)
    plt.figure(figsize=(12, 8))
    segment_counts = data["customer_segment"].value_counts()
    colors = [segment_colors.get(seg, "#95A5A6") for seg in segment_counts.index]

    bars = plt.barh(segment_counts.index, segment_counts.values, color=colors)
    plt.title(
        "Customer Segment Distribution\n(Number of Customers by Segment)",
        fontsize=14,
        fontweight="bold",
        pad=20,
    )
    plt.xlabel("Number of Customers", fontsize=12)
    plt.ylabel("")

    # Add value labels on bars
    for bar in bars:
        width = bar.get_width()
        plt.text(
            width + width * 0.01,
            bar.get_y() + bar.get_height() / 2,
            f"{int(width):,}",
            ha="left",
            va="center",
            fontweight="bold",
        )

    plt.grid(axis="x", alpha=0.3)
    plt.tight_layout()
    plt.show()

    # Chart 2: RFM Analysis Scatter Plot
    plt.figure(figsize=(12, 8))

    for segment in data["customer_segment"].unique():
        segment_data = data[data["customer_segment"] == segment]
        plt.scatter(
            segment_data["days_since_last_purchase"] / 30,
            segment_data["total_purchases"],
            c=segment_colors.get(segment, "#95A5A6"),
            label=segment,
            alpha=0.7,
            s=60,
        )

    plt.xlabel("Median Recency (months)", fontsize=12)
    plt.ylabel("Median Frequency", fontsize=12)
    plt.title(
        "Customer Segmentation Analysis\n(Recency vs Frequency)",
        fontsize=14,
        fontweight="bold",
    )
    plt.legend(bbox_to_anchor=(1.05, 1), loc="upper left")
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.show()

    plt.figure(figsize=(12, 8))

    from sklearn.decomposition import PCA

    clustering_features = data[
        ["total_purchases", "total_spent", "days_since_last_purchase"]
    ].fillna(0)

    # Scale features
    scaler = StandardScaler()
    scaled_features = scaler.fit_transform(clustering_features)

    # Apply PCA for 2D visualization
    pca = PCA(n_components=2)
    pca_features = pca.fit_transform(scaled_features)

    # Apply K-means clustering
    kmeans = KMeans(n_clusters=5, random_state=42, n_init=10)
    cluster_labels = kmeans.fit_predict(scaled_features)

    # Plot clusters
    cluster_colors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7"]

    for i in range(5):
        cluster_mask = cluster_labels == i
        plt.scatter(
            pca_features[cluster_mask, 0],
            pca_features[cluster_mask, 1],
            c=cluster_colors[i],
            label=f"Cluster {i+1}",
            alpha=0.6,
            s=50,
        )

    # Plot centroids
    pca_centroids = pca.transform(kmeans.cluster_centers_)
    plt.scatter(
        pca_centroids[:, 0],
        pca_centroids[:, 1],
        c="yellow",
        marker="o",
        s=200,
        alpha=0.8,
        edgecolors="black",
        linewidth=2,
        label="Centroids",
    )

    plt.title(
        "Clusters of Customers\n(K-Means Algorithm Visualization)",
        fontsize=14,
        fontweight="bold",
    )
    plt.xlabel("Principal Component 1", fontsize=12)
    plt.ylabel("Principal Component 2", fontsize=12)
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.show()

    # Chart 4: Business Value Analysis
    # Calculate segment metrics
    segment_metrics = (
        data.groupby("customer_segment")
        .agg(
            {
                "customer_id": "count",
                "total_spent": "mean",
                "total_purchases": "mean",
                "days_since_last_purchase": "mean",
            }
        )
        .round(2)
    )

    segment_metrics.columns = ["Count", "Avg_Spent", "Avg_Purchases", "Avg_Recency"]

    # Create subplot for business metrics
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 10))
    fig.suptitle(
        "Business Intelligence: Customer Segment Analysis",
        fontsize=16,
        fontweight="bold",
        y=0.98,
    )

    # Revenue per segment
    colors_list = [segment_colors.get(seg, "#95A5A6") for seg in segment_metrics.index]
    bars1 = ax1.bar(
        segment_metrics.index, segment_metrics["Avg_Spent"], color=colors_list
    )
    ax1.set_title("Average Customer Value", fontweight="bold", pad=15)
    ax1.set_ylabel("Average Total Spent ($)")
    ax1.tick_params(axis="x", rotation=45, labelsize=9)
    plt.setp(ax1.xaxis.get_majorticklabels(), ha="right")

    for bar in bars1:
        height = bar.get_height()
        ax1.text(
            bar.get_x() + bar.get_width() / 2.0,
            height + height * 0.01,
            f"${height:.0f}",
            ha="center",
            va="bottom",
            fontweight="bold",
            fontsize=9,
        )
    
    # Adjust y-axis to accommodate labels
    ax1.set_ylim(0, segment_metrics["Avg_Spent"].max() * 1.15)

    # Purchase frequency
    bars2 = ax2.bar(
        segment_metrics.index, segment_metrics["Avg_Purchases"], color=colors_list
    )
    ax2.set_title("Average Purchase Frequency", fontweight="bold", pad=15)
    ax2.set_ylabel("Average Number of Purchases")
    ax2.tick_params(axis="x", rotation=45, labelsize=9)
    plt.setp(ax2.xaxis.get_majorticklabels(), ha="right")

    for bar in bars2:
        height = bar.get_height()
        ax2.text(
            bar.get_x() + bar.get_width() / 2.0,
            height + height * 0.01,
            f"{height:.1f}",
            ha="center",
            va="bottom",
            fontweight="bold",
            fontsize=9,
        )
    
    # Adjust y-axis to accommodate labels
    ax2.set_ylim(0, segment_metrics["Avg_Purchases"].max() * 1.15)

    # Customer count
    bars3 = ax3.bar(segment_metrics.index, segment_metrics["Count"], color=colors_list)
    ax3.set_title("Segment Size", fontweight="bold", pad=15)
    ax3.set_ylabel("Number of Customers")
    ax3.tick_params(axis="x", rotation=45, labelsize=9)
    plt.setp(ax3.xaxis.get_majorticklabels(), ha="right")

    for bar in bars3:
        height = bar.get_height()
        ax3.text(
            bar.get_x() + bar.get_width() / 2.0,
            height + height * 0.01,
            f"{int(height):,}",
            ha="center",
            va="bottom",
            fontweight="bold",
            fontsize=9,
        )
    
    # Adjust y-axis to accommodate labels
    ax3.set_ylim(0, segment_metrics["Count"].max() * 1.15)

    # Recency analysis
    bars4 = ax4.bar(
        segment_metrics.index, segment_metrics["Avg_Recency"], color=colors_list
    )
    ax4.set_title("Average Days Since Last Purchase", fontweight="bold", pad=15)
    ax4.set_ylabel("Days")
    ax4.tick_params(axis="x", rotation=45, labelsize=9)
    plt.setp(ax4.xaxis.get_majorticklabels(), ha="right")

    for bar in bars4:
        height = bar.get_height()
        ax4.text(
            bar.get_x() + bar.get_width() / 2.0,
            height + height * 0.01,
            f"{height:.0f}",
            ha="center",
            va="bottom",
            fontweight="bold",
            fontsize=9,
        )
    
    # Adjust y-axis to accommodate labels
    ax4.set_ylim(0, segment_metrics["Avg_Recency"].max() * 1.15)

    plt.tight_layout(pad=2.0)
    plt.show()

    return segment_metrics


def print_segment_analysis(data):
    """Print detailed analysis of customer segments for marketing strategy"""

    print("\n" + "=" * 80)
    print("CUSTOMER SEGMENTATION ANALYSIS FOR EMAIL MARKETING CAMPAIGNS")
    print("=" * 80)

    segment_analysis = (
        data.groupby("customer_segment")
        .agg(
            {
                "customer_id": "count",
                "total_spent": ["mean", "sum"],
                "total_purchases": "mean",
                "avg_purchase_value": "mean",
                "days_since_last_purchase": "mean",
                "engagement_rate": "mean",
                "purchase_intensity": "mean",
            }
        )
        .round(2)
    )

    # Flatten column names
    segment_analysis.columns = [
        f"{col[0]}_{col[1]}" if col[1] else col[0] for col in segment_analysis.columns
    ]

    total_customers = len(data)
    total_revenue = data["total_spent"].sum()

    print(f"\nTotal Customers Analyzed: {total_customers:,}")
    print(f"Total Revenue: ${total_revenue:,.2f}")
    print("\nSEGMENT BREAKDOWN:")
    print("-" * 80)

    for segment in segment_analysis.index:
        count = int(segment_analysis.loc[segment, "customer_id_count"])
        percentage = (count / total_customers) * 100
        avg_spent = segment_analysis.loc[segment, "total_spent_mean"]
        total_segment_revenue = segment_analysis.loc[segment, "total_spent_sum"]
        revenue_percentage = (total_segment_revenue / total_revenue) * 100
        avg_purchases = segment_analysis.loc[segment, "total_purchases_mean"]
        avg_order_value = segment_analysis.loc[segment, "avg_purchase_value_mean"]
        recency = segment_analysis.loc[segment, "days_since_last_purchase_mean"]

        print(f"\n🎯 {segment.upper()}")
        print(f"   Size: {count:,} customers ({percentage:.1f}% of total)")
        print(
            f"   Revenue: ${total_segment_revenue:,.2f} ({revenue_percentage:.1f}% of total)"
        )
        print(f"   Avg Lifetime Value: ${avg_spent:.2f}")
        print(f"   Avg Purchase Frequency: {avg_purchases:.1f}")
        print(f"   Avg Order Value: ${avg_order_value:.2f}")
        print(f"   Avg Days Since Last Purchase: {recency:.0f}")

        # Marketing recommendations
        if segment == "New Customer":
            print(
                "   📧 EMAIL STRATEGY: Welcome series, onboarding offers, first-purchase incentives"
            )
        elif segment == "Inactive Customer":
            print(
                "   📧 EMAIL STRATEGY: Win-back campaigns, special discounts, re-engagement series"
            )
        elif segment == "Platinum Customer":
            print(
                "   📧 EMAIL STRATEGY: VIP treatment, exclusive offers, early access, loyalty rewards"
            )
        elif segment == "Gold Customer":
            print(
                "   📧 EMAIL STRATEGY: Premium offers, upselling, loyalty program invites"
            )
        elif segment == "Silver Customer":
            print("   📧 EMAIL STRATEGY: Value offers, cross-selling, loyalty building")
        else:
            print(
                "   📧 EMAIL STRATEGY: General promotions, product recommendations, engagement content"
            )


def main():
    """Main function to run customer segmentation analysis"""

    print("Starting Customer Segmentation Analysis for Commercial Targeting...")
    print("Extracting customer behavioral data...")

    # Extract customer features
    customer_data = extract_customer_features()
    if customer_data is None:
        print("Failed to extract customer data. Exiting.")
        return

    print(f"Successfully loaded data for {len(customer_data)} customers")

    # Create customer segments
    print("Creating customer segments using clustering algorithms...")
    segmented_data, kmeans_model, scaler = create_customer_segments(customer_data)

    # Create visualizations
    print("Generating customer segment visualizations...")
    segment_metrics = create_four_key_visualizations(segmented_data)

    # Print detailed analysis
    print_segment_analysis(segmented_data)

    print("\n" + "=" * 80)
    print("CLUSTERING MODEL PERFORMANCE")
    print("=" * 80)

    print(f"Number of Clusters Used: {len(segmented_data['cluster'].unique())}")
    print(
        f"Business Segments Created: {len(segmented_data['customer_segment'].unique())}"
    )

    segment_distribution = segmented_data["customer_segment"].value_counts()
    print(f"\nSegment Distribution:")
    for segment, count in segment_distribution.items():
        percentage = (count / len(segmented_data)) * 100
        print(f"  {segment}: {count:,} customers ({percentage:.1f}%)")

    print("\n✅ Customer segmentation analysis complete!")
    print("📊 4 comprehensive visualizations generated successfully!")
    print("🎯 Use these segments for targeted email marketing campaigns.")

    try:
        input("\nPress Enter to exit...")
    except KeyboardInterrupt:
        print("\n\nProgram interrupted by user. Exiting gracefully...")
        plt.close('all')


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nProgram interrupted by user. Exiting gracefully...")
        plt.close('all')
