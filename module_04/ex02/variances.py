import sys
import pandas as pd
import numpy as np
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
import matplotlib.pyplot as plt

def main():
    filepath = sys.argv[1] if len(sys.argv) > 1 else "../Train_knight.csv"
    try:
        df = pd.read_csv(filepath)
    except FileNotFoundError:
        print(f"Error: Could not find file {filepath}")
        sys.exit(1)
        
    # Drop the target column if it exists
    if 'knight' in df.columns:
        X = df.drop('knight', axis=1)
    else:
        X = df
        
    # Standardize the features before PCA
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)
    
    # Perform PCA
    pca = PCA()
    pca.fit(X_scaled)
    
    # Explained variance in percentage
    variances = pca.explained_variance_ratio_ * 100
    cumulative_variances = np.cumsum(variances)
    
    # Format the arrays nicely as requested in the example
    print("Variances (Percentage):")
    # Using np.array2string for nice formatting
    print(np.array2string(variances, formatter={'float_kind':lambda x: f"{x:e}"}))
    print()
    print("Cumulative Variances (Percentage):")
    print(np.array2string(cumulative_variances, precision=8, suppress_small=True))
    
    # Display a graph representing the addition of variances
    plt.figure(figsize=(8, 6))
    plt.plot(range(1, len(cumulative_variances) + 1), cumulative_variances)
    plt.xlabel('Number of components')
    plt.ylabel('Explained variance (%)')
    plt.title('Cumulative Explained Variance by PCA Components')
    plt.grid(True)
    plt.show()

if __name__ == "__main__":
    main()
