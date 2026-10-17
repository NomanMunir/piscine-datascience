#!/usr/bin/env python3
import sys
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap

def load_labels(filepath: str) -> list:
    """Load labels from a text file (one label per line)."""
    try:
        with open(filepath, 'r') as f:
            labels = [line.strip() for line in f.readlines() if line.strip()]
        return labels
    except FileNotFoundError:
        print(f"Error: File not found: {filepath}")
        sys.exit(1)

def calculate_confusion_matrix(y_true: list, y_pred: list, classes: list) -> list:
    """Calculate confusion matrix manually."""
    if len(y_true) != len(y_pred):
        print("Error: Length of truth and predictions must match")
        sys.exit(1)
        
    matrix = [[0, 0], [0, 0]]
    
    for true, pred in zip(y_true, y_pred):
        try:
            true_idx = classes.index(true)
            pred_idx = classes.index(pred)
            matrix[true_idx][pred_idx] += 1
        except ValueError:
            print(f"Error: Unrecognized label found. Expected {classes}")
            sys.exit(1)
            
    return matrix

def calculate_metrics(cm: list, classes: list) -> dict:
    """Calculate precision, recall, f1-score from confusion matrix."""
    metrics = {}
    total = sum(sum(row) for row in cm)
    correct = cm[0][0] + cm[1][1]
    
    for i, cls in enumerate(classes):
        tp = cm[i][i]
        fp = sum(cm[j][i] for j in range(len(classes))) - tp
        fn = sum(cm[i]) - tp
        support = sum(cm[i])
        
        precision = tp / (tp + fp) if (tp + fp) > 0 else 0
        recall = tp / (tp + fn) if (tp + fn) > 0 else 0
        f1 = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0
        
        metrics[cls] = {
            'precision': precision,
            'recall': recall,
            'f1-score': f1,
            'support': support
        }
    
    metrics['accuracy'] = correct / total if total > 0 else 0
    metrics['total'] = total
    
    return metrics

def display_confusion_matrix(cm: list, classes: list):
    """Display confusion matrix as a heatmap."""
    colors = ['#2d6a4f', '#40916c', '#ffd166', '#9b5de5']
    custom_cmap = LinearSegmentedColormap.from_list('custom', colors, N=256)
    
    fig, ax = plt.subplots(figsize=(8, 6))
    im = ax.imshow(cm, cmap=custom_cmap)
    
    ax.set_xticks(range(len(classes)))
    ax.set_yticks(range(len(classes)))
    ax.set_xticklabels(classes)
    ax.set_yticklabels(classes)
    
    ax.set_xlabel('Predicted', fontsize=12)
    ax.set_ylabel('Actual', fontsize=12)
    ax.set_title('Confusion Matrix', fontsize=14, fontweight='bold')
    
    for i in range(len(classes)):
        for j in range(len(classes)):
            ax.text(j, i, cm[i][j], ha='center', va='center', 
                    fontsize=20, fontweight='bold', color='white')
    
    plt.colorbar(im)
    plt.tight_layout()
    plt.show()

def main():
    if len(sys.argv) != 3:
        print("Usage: python Confusion_Matrix.py <predictions.txt> <truth.txt>")
        sys.exit(1)
        
    predictions_file = sys.argv[1]
    truth_file = sys.argv[2]
    
    predictions = load_labels(predictions_file)
    truth = load_labels(truth_file)
    
    classes = ['Jedi', 'Sith']
    cm = calculate_confusion_matrix(truth, predictions, classes)
    metrics = calculate_metrics(cm, classes)
    
    print(f"{'':>12} {'precision':>10} {'recall':>10} {'f1-score':>10} {'total':>10}")
    print()
    for cls in classes:
        m = metrics[cls]
        print(f"{cls:>12} {m['precision']:>10.2f} {m['recall']:>10.2f} {m['f1-score']:>10.2f} {m['support']:>10}")
    print()
    print(f"{'accuracy':>12} {metrics['accuracy']:>32.2f} {metrics['total']:>10}")
    print()
    print(f"[[{cm[0][0]} {cm[0][1]}]")
    print(f" [{cm[1][0]} {cm[1][1]}]]")
    
    display_confusion_matrix(cm, classes)

if __name__ == "__main__":
    main()
