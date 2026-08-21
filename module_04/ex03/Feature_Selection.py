import sys
import pandas as pd
from statsmodels.stats.outliers_influence import variance_inflation_factor

def calculate_vif(X):
    vif_data = pd.DataFrame()
    vif_data["Feature"] = X.columns
    vif_data["VIF"] = [variance_inflation_factor(X.values, i) for i in range(len(X.columns))]
    vif_data["Tolerance"] = 1 / vif_data["VIF"]
    return vif_data

def main():
    filepath = sys.argv[1] if len(sys.argv) > 1 else "../Train_knight.csv"
    try:
        df = pd.read_csv(filepath)
    except FileNotFoundError:
        print(f"Error: Could not find file {filepath}")
        sys.exit(1)
        
    if 'knight' in df.columns:
        X = df.drop('knight', axis=1)
    else:
        X = df
        
    vif_df = calculate_vif(X)
    print(f"{'':<15} {'VIF':>10} {'Tolerance':>10}")
    for _, row in vif_df.iterrows():
        print(f"{row['Feature']:<15} {row['VIF']:10.6f} {row['Tolerance']:10.6f}")
    print("\nReducing features to keep VIF under 5...")
    
    # Iteratively remove feature with highest VIF until all are < 5
    while True:
        vif_df = calculate_vif(X)
        max_vif = vif_df["VIF"].max()
        if max_vif > 5.0:
            # Find the feature with the highest VIF
            feature_to_remove = vif_df.loc[vif_df["VIF"].idxmax(), "Feature"]
            # print(f"Removing {feature_to_remove} (VIF: {max_vif:.2f})")
            X = X.drop(columns=[feature_to_remove])
        else:
            break
            
    print("\nFinal features with VIF under 5:")
    final_vif = calculate_vif(X)
    print(f"{'':<15} {'VIF':>10} {'Tolerance':>10}")
    for _, row in final_vif.iterrows():
        print(f"{row['Feature']:<15} {row['VIF']:10.6f} {row['Tolerance']:10.6f}")

if __name__ == "__main__":
    main()
