import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import AgglomerativeClustering
from sklearn.decomposition import PCA
import matplotlib.pyplot as plt
from sklearn.metrics import silhouette_score, calinski_harabasz_score, davies_bouldin_score

dataset = pd.read_csv("StudentPerformanceFactors.csv")
#print(dataset.head())

## Data Cleaning

# Eliminate missing values
dataset.isnull().sum()
dataset = dataset.dropna()

# Eliminate duplicate values
dataset.duplicated().sum() # no duplicated values

# Eliminate inconsistent values
dataset.drop(dataset[dataset['Exam_Score'] > 100].index , inplace = True)
dataset.drop(dataset[dataset['Exam_Score'] < 0].index , inplace = True)
dataset.drop(dataset[dataset['Attendance'] > 100].index , inplace = True)
dataset.drop(dataset[dataset['Attendance'] < 0].index , inplace = True)
dataset.drop(dataset[dataset['Previous_Scores'] > 100].index , inplace = True)
dataset.drop(dataset[dataset['Previous_Scores'] < 0].index , inplace = True)

# reset index
dataset.reset_index(drop=True, inplace=True)

## Data Transformation

categorical_features = ['Extracurricular_Activities', 'Internet_Access', 'School_Type', 'Learning_Disabilities', 'Gender', 'Parental_Involvement', 'Access_to_Resources', 'Motivation_Level', 'Family_Income', 'Teacher_Quality', 'Peer_Influence', 'Parental_Education_Level', 'Distance_from_Home']

continuous_features = ['Hours_Studied', 'Attendance', 'Previous_Scores', 'Sleep_Hours', 'Tutoring_Sessions', 'Physical_Activity', 'Exam_Score']
# encoding categorical features

encoded_categorical_features = pd.get_dummies(dataset[categorical_features], drop_first=False)
print(encoded_categorical_features.head())

# Create processed_dataset by dropping original categorical columns and concatenating one-hot encoded ones

processed_dataset = dataset.drop(columns=categorical_features).copy()
processed_dataset = pd.concat([processed_dataset, encoded_categorical_features], axis=1)

processed_dataset.to_csv('processed_data.csv', index = False)
    
## Sampling
features_column = [f for f in encoded_categorical_features.columns] + [f for f in continuous_features]
     
## Normalize the numerical features
scaler = StandardScaler()
features_scaled = scaler.fit_transform(processed_dataset[features_column].values)

# Perform AGNES Clustering
# We'll choose n_clusters = 3 for demonstration. You can adjust this number.
n_clusters = 4
agnes = AgglomerativeClustering(n_clusters=n_clusters)
clusters = agnes.fit_predict(features_scaled)

print(f"Number of clusters: {n_clusters}")
print(f"Cluster assignments (first 10): {clusters[:10]}")

# Dimensionality Reduction using PCA for 2D Visualization
pca = PCA(n_components=2)
principal_components = pca.fit_transform(features_scaled)

# Create a DataFrame for easier plotting
pca_df = pd.DataFrame(data=principal_components, columns=['PC1', 'PC2'])
pca_df['Cluster'] = clusters

# Visualize the clusters
plt.figure(figsize=(10, 8))
scatter = plt.scatter(pca_df['PC1'], pca_df['PC2'], c=pca_df['Cluster'], cmap='viridis', s=50, alpha=0.8)
plt.title('AGNES Clustering Visualization (2D PCA)')
plt.xlabel('Principal Component 1')
plt.ylabel('Principal Component 2')
plt.colorbar(scatter, label='Cluster ID')
plt.grid(True)
plt.show()

# Optional: Display the count of points in each cluster
print("\nPoints per cluster:")
print(pca_df['Cluster'].value_counts().sort_index())

# Dimensionality Reduction using PCA for 3D Visualization
pca_3d = PCA(n_components=3)
principal_components_3d = pca_3d.fit_transform(features_scaled)

# Create a DataFrame for easier plotting
pca_3d_df = pd.DataFrame(data=principal_components_3d, columns=['PC1', 'PC2', 'PC3'])
pca_3d_df['Cluster'] = clusters

# Visualize the clusters in 3D
fig = plt.figure(figsize=(12, 10))
ax = fig.add_subplot(111, projection='3d')

# Scatter plot
scatter = ax.scatter(pca_3d_df['PC1'], pca_3d_df['PC2'], pca_3d_df['PC3'],
                     c=pca_3d_df['Cluster'], cmap='viridis', s=50, alpha=0.8)

ax.set_title('AGNES Clustering Visualization (3D PCA)')
ax.set_xlabel('Principal Component 1')
ax.set_ylabel('Principal Component 2')
ax.set_zlabel('Principal Component 3')
fig.colorbar(scatter, label='Cluster ID', shrink=0.7, aspect=10)

# Define a set of viewing angles (elevation, azimuth)
viewing_angles = [
    (20, -60),
    (30, 45),
    (10, 120),
    (45, 0),    # Top-down view
    (0, 90),    # Side view along PC1
    (90, 0)     # Directly from above
] # (elevation, azimuth)

# Visualize the clusters from different angles
for i, (elev, azim) in enumerate(viewing_angles):
    fig = plt.figure(figsize=(12, 10)) # Create a new figure for each angle
    ax = fig.add_subplot(111, projection='3d') # Add new 3D axes to the new figure

    # Scatter plot
    scatter = ax.scatter(pca_3d_df['PC1'], pca_3d_df['PC2'], pca_3d_df['PC3'],
                         c=pca_3d_df['Cluster'], cmap='viridis', s=50, alpha=0.8)

    ax.set_title(f'AGNES Clustering Visualization (3D PCA) - View {i+1} (Elev: {elev}, Azim: {azim})')
    ax.set_xlabel('Principal Component 1')
    ax.set_ylabel('Principal Component 2')
    ax.set_zlabel('Principal Component 3')
    fig.colorbar(scatter, label='Cluster ID', shrink=0.7, aspect=10)

    ax.view_init(elev=elev, azim=azim)
    plt.show() # Display each view as a separate plot

# Clustering Evaluation
try:
    silhouette_avg = silhouette_score(features_scaled, clusters)
    davis_avg = davies_bouldin_score(features_scaled, clusters)
    calinski_avg = calinski_harabasz_score(features_scaled, clusters)
    print(f"Silhouette Score: {silhouette_avg:.4f}")
    print(f"Calinski-Harabasz Index: {calinski_avg:.4f}")
    print(f"Davies-Bouldin Index: {davis_avg:.4f}")
except ValueError as e:
    print(f"Could not calculate clustering evaluation metrics: {e}")
    print("This might happen if there's only one cluster or too few samples per cluster.")




