import sys
import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.neighbors import KNeighborsClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import accuracy_score

def main():
    if len(sys.argv) != 3:
        print("Usage: python KNN.py <Train_knight.csv> <Test_knight.csv>")
        sys.exit(1)
        
    train_file = sys.argv[1]
    test_file = sys.argv[2]
    val_file = "../Validation_knight.csv"
    
    try:
        train_df = pd.read_csv(train_file)
        test_df = pd.read_csv(test_file)
    except FileNotFoundError as e:
        print(f"Error: {e}")
        sys.exit(1)
        
    # Use Validation set if available to find best k
    val_df = None
    if os.path.exists(val_file):
        val_df = pd.read_csv(val_file)
    elif os.path.exists("../../module_03/ex05/Validation_knight.csv"):
        val_df = pd.read_csv("../../module_03/ex05/Validation_knight.csv")
        
    X_train = train_df.drop('knight', axis=1)
    y_train = train_df['knight']
    
    if 'knight' in test_df.columns:
        X_test = test_df.drop('knight', axis=1)
    else:
        X_test = test_df
    X_test = X_test[X_train.columns]
    
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    best_k = 5
    if val_df is not None:
        X_val = val_df.drop('knight', axis=1)
        X_val = X_val[X_train.columns]
        y_val = val_df['knight']
        X_val_scaled = scaler.transform(X_val)
        
        k_values = range(1, 30)
        accuracies = []
        
        for k in k_values:
            knn = KNeighborsClassifier(n_neighbors=k)
            knn.fit(X_train_scaled, y_train)
            preds = knn.predict(X_val_scaled)
            acc = accuracy_score(y_val, preds)
            accuracies.append(acc)
            
        best_k = k_values[np.argmax(accuracies)]
        
        plt.figure(figsize=(8, 6))
        plt.plot(k_values, accuracies)
        plt.xlabel('k values')
        plt.ylabel('accuracy')
        plt.tight_layout()
        plt.show()
    
    # Train with best k
    knn = KNeighborsClassifier(n_neighbors=best_k)
    knn.fit(X_train_scaled, y_train)
    predictions = knn.predict(X_test_scaled)
    
    with open('KNN.txt', 'w') as f:
        for pred in predictions:
            f.write(f"{pred}\n")

if __name__ == "__main__":
    main()
