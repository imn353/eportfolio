import pandas as pd
from sklearn.neighbors import KNeighborsClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score, precision_score, recall_score, f1_score
from sklearn import metrics
import matplotlib.pyplot as plt

# Load the preprocessed data
student_data = pd.read_csv('modif_student_performance.csv')
print("Dataset shape:", student_data.shape)

# Prepare features and target variable
# Select only the encoded/binned features for training
feature_columns = [col for col in student_data.columns if ('_encoded' in col or '_binned' in col) and col != 'Exam_Score_binned']

print(f"\nSelected feature columns: {len(feature_columns)}")
X = student_data[feature_columns]
y = student_data['Exam_Score_binned']  # Using binned exam score as target

print(f"\nFeatures selected: {len(feature_columns)}")
print("Feature columns:", feature_columns)
print(f"\nTarget variable distribution:")
print((y.value_counts().sort_index()/y.shape[0])*100)  # Display distribution of target variable

# Split the data
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42, stratify=y)

print(f"\nTraining set size: {X_train.shape}")
print(f"Test set size: {X_test.shape}")

# Scale the features (important for KNN as it uses distance)
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

print("\n" + "="*50)
print("TRAINING KNN MODELS")
print("="*50)

# Test different distance metrics
k_values = [3, 5, 7, 9, 11, 15, 19]

# Store results for different configurations
results = {}

# Test different k values with multiple metrics (Euclidean distance)
print("\n1. Testing different k values with multiple metrics (Euclidean distance):")
print("-" * 80)

# Store results for different metrics
k_results = {
    'k': [],
    'accuracy': [],
    'precision': [],
    'recall': [],
    'f1_score': []
}

# Test different k values with multiple evaluation metrics
for k in k_values:
    knn = KNeighborsClassifier(n_neighbors=k, metric='euclidean')
    knn.fit(X_train_scaled, y_train)
    y_pred = knn.predict(X_test_scaled)
    
    # Calculate multiple metrics
    accuracy = accuracy_score(y_test, y_pred)
    precision = precision_score(y_test, y_pred, average='weighted', zero_division=0)
    recall = recall_score(y_test, y_pred, average='weighted', zero_division=0)
    f1 = f1_score(y_test, y_pred, average='weighted', zero_division=0)
    
    # Store results
    k_results['k'].append(k)
    k_results['accuracy'].append(accuracy)
    k_results['precision'].append(precision)
    k_results['recall'].append(recall)
    k_results['f1_score'].append(f1)
    
    print(f"k={k:2d}: Accuracy={accuracy:.4f}, Precision={precision:.4f}, Recall={recall:.4f}, F1={f1:.4f}")

# Convert to DataFrame for easier analysis
k_results_df = pd.DataFrame(k_results)
print(f"\nSummary of results:")
print(k_results_df.round(4))

# Find best k for each metric
best_k_accuracy = k_results_df.loc[k_results_df['accuracy'].idxmax(), 'k']
best_k_precision = k_results_df.loc[k_results_df['precision'].idxmax(), 'k']
best_k_recall = k_results_df.loc[k_results_df['recall'].idxmax(), 'k']
best_k_f1 = k_results_df.loc[k_results_df['f1_score'].idxmax(), 'k']

print(f"\nBest k values for each metric:")
print(f"Accuracy:  k={best_k_accuracy} ({k_results_df.loc[k_results_df['k']==best_k_accuracy, 'accuracy'].values[0]:.4f})")
print(f"Precision: k={best_k_precision} ({k_results_df.loc[k_results_df['k']==best_k_precision, 'precision'].values[0]:.4f})")
print(f"Recall:    k={best_k_recall} ({k_results_df.loc[k_results_df['k']==best_k_recall, 'recall'].values[0]:.4f})")
print(f"F1-Score:  k={best_k_f1} ({k_results_df.loc[k_results_df['k']==best_k_f1, 'f1_score'].values[0]:.4f})")

# Use F1-score as the primary metric for selecting best k (you can change this)
best_k_overall = best_k_f1
print(f"\nUsing k={best_k_overall} as best overall (based on F1-score)")

# Final model with best k and best distance metric
final_model = KNeighborsClassifier(n_neighbors=best_k_overall, metric='euclidean')
final_model.fit(X_train_scaled, y_train)
final_predictions = final_model.predict(X_test_scaled)

# Evaluate final model
final_accuracy = accuracy_score(y_test, final_predictions)
print(f"\nFinal Model Evaluation:")
print(f"Accuracy: {final_accuracy:.4f}")
print("Classification Report:")
print(classification_report(y_test, final_predictions, zero_division=0))
print("\nConfusion Matrix:")
cm = confusion_matrix(y_test, final_predictions)
print(cm)
cm_display = metrics.ConfusionMatrixDisplay(confusion_matrix = cm, display_labels = student_data['Exam_Score_binned'].unique())
cm_display.plot(cmap='Blues')
plt.title('Confusion Matrix')
plt.show()
