import sys
import pandas as pd
from sklearn.tree import DecisionTreeClassifier
from sklearn.neighbors import KNeighborsClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import VotingClassifier
from sklearn.preprocessing import StandardScaler

def main():
    if len(sys.argv) != 3:
        print("Usage: python democracy.py <Train_knight.csv> <Test_knight.csv>")
        sys.exit(1)
        
    train_file = sys.argv[1]
    test_file = sys.argv[2]
    
    try:
        train_df = pd.read_csv(train_file)
        test_df = pd.read_csv(test_file)
    except FileNotFoundError as e:
        print(f"Error: {e}")
        sys.exit(1)
        
    X_train = train_df.drop('knight', axis=1)
    y_train = train_df['knight']
    
    if 'knight' in test_df.columns:
        X_test = test_df.drop('knight', axis=1)
    else:
        X_test = test_df
    X_test = X_test[X_train.columns]
    
    # Scale data (important for KNN and Logistic Regression)
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    # Initialize the 3 models based on the diagram
    clf1 = DecisionTreeClassifier(random_state=42, max_depth=5)
    clf2 = LogisticRegression(random_state=42, max_iter=1000)
    clf3 = KNeighborsClassifier(n_neighbors=5)
    
    # Create Voting Classifier
    eclf = VotingClassifier(
        estimators=[('dt', clf1), ('lr', clf2), ('knn', clf3)],
        voting='hard'
    )
    
    # Train
    eclf.fit(X_train_scaled, y_train)
    
    # Predict
    predictions = eclf.predict(X_test_scaled)
    
    # Write to Voting.txt
    with open('Voting.txt', 'w') as f:
        for pred in predictions:
            f.write(f"{pred}\n")

if __name__ == "__main__":
    main()
