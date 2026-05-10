import pandas as pd
import joblib

from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import (
    train_test_split,
    cross_val_score
)

from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    roc_auc_score,
    confusion_matrix,
    classification_report
)

from imblearn.over_sampling import SMOTE

# LOAD DATASET
df = pd.read_csv("migraine_dataset.csv")

# CLEAN
df = df.dropna()

features = [
    'sleep_hours',
    'stress_level',
    'hydration_level',
    'screen_time',
    'mood_level'
]

target = 'migraine_severity'

X = df[features]
y = df[target]

# BEFORE SMOTE
print("\nBefore SMOTE:")
print(y.value_counts())

# APPLY SMOTE
smote = SMOTE(random_state=42)

X, y = smote.fit_resample(X, y)

# AFTER SMOTE
print("\nAfter SMOTE:")
print(y.value_counts())

# SPLIT
X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.2,
    random_state=42
)

# MODEL
model = RandomForestClassifier(
    n_estimators=100,
    max_depth=5,
    random_state=42
)

# TRAIN
model.fit(X_train, y_train)

# PREDICT
y_pred = model.predict(X_test)

# METRICS
accuracy = accuracy_score(y_test, y_pred)
precision = precision_score(y_test, y_pred, average='weighted')
recall = recall_score(y_test, y_pred, average='weighted')
f1 = f1_score(y_test, y_pred, average='weighted')

print("\n===== MODEL EVALUATION =====")
print("Accuracy:", accuracy)
print("Precision:", precision)
print("Recall:", recall)
print("F1 Score:", f1)

# CONFUSION MATRIX
print("\nConfusion Matrix:")
print(confusion_matrix(y_test, y_pred))

# CLASSIFICATION REPORT
print("\nClassification Report:")
print(classification_report(y_test, y_pred))

# CROSS VALIDATION
scores = cross_val_score(model, X, y, cv=10)

print("\nCross Validation Scores:")
print(scores)

print("Average Accuracy:", scores.mean())

# SAVE MODEL
joblib.dump(model, "migraine_model.pkl")

print("\n✅ Model trained successfully!")