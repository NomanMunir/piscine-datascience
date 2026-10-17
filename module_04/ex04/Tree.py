#!/usr/bin/env python3
import sys
import pandas as pd
from sklearn.tree import DecisionTreeClassifier, plot_tree
import matplotlib.pyplot as plt

def main():
    if len(sys.argv) != 3:
        print("Usage: python Tree.py <Train_knight.csv> <Test_knight.csv>")
        sys.exit(1)
        
    train_file = sys.argv[1]
    test_file = sys.argv[2]
    
    try:
        train_df = pd.read_csv(train_file)
        test_df = pd.read_csv(test_file)
    except FileNotFoundError as e:
        print(f"Error: {e}")
        sys.exit(1)
        
    # We will use the VIF selected features or just all features.
    # A decision tree doesn't suffer much from multicollinearity.
    
    X_train = train_df.drop('knight', axis=1)
    y_train = train_df['knight']
    
    # We will assume test_df has no 'knight' column, but if it does we drop it
    if 'knight' in test_df.columns:
        X_test = test_df.drop('knight', axis=1)
    else:
        X_test = test_df
        
    # Ensure columns match
    X_test = X_test[X_train.columns]
    
    # Train Decision Tree
    clf = DecisionTreeClassifier(random_state=42, max_depth=5)
    clf.fit(X_train, y_train)
    
    # Make predictions
    predictions = clf.predict(X_test)
    
    # Write to Tree.txt
    with open('Tree.txt', 'w') as f:
        for pred in predictions:
            f.write(f"{pred}\n")
            
    # Display the tree
    plt.figure(figsize=(20, 10))
    plot_tree(clf, filled=True, feature_names=X_train.columns, class_names=clf.classes_)
    plt.title('Decision tree trained on all Knights features')
    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    main()
