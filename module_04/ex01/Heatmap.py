#!/usr/bin/env python3
import sys
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

def main():
    filepath = sys.argv[1] if len(sys.argv) > 1 else "../Train_knight.csv"
    try:
        df = pd.read_csv(filepath)
    except FileNotFoundError:
        print(f"Error: Could not find file {filepath}")
        sys.exit(1)
        
    # The 'knight' column is categorical (Jedi/Sith). We can map it to numbers for correlation,
    # or just drop it. The example image includes 'knight' at the bottom, so let's map it.
    if 'knight' in df.columns:
        df['knight'] = df['knight'].map({'Jedi': 1, 'Sith': 0})
        
    # Calculate correlation matrix
    corr = df.corr()
    
    # Plot heatmap
    plt.figure(figsize=(12, 10))
    sns.heatmap(corr, annot=False, cmap='rocket', vmin=-1, vmax=1)
    plt.title('Correlation Coefficient Heatmap', fontsize=16)
    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    main()
