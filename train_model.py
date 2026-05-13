import pandas as pd
import joblib

from sklearn.preprocessing import label_binarize

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

from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier

from xgboost import XGBClassifier

from imblearn.over_sampling import SMOTE

# LOAD DATASET
df = pd.read_csv("migraine_dataset.csv")

# REMOVE NULL VALUES
df = df.dropna()

# FEATURES
features = [
    'sleep_hours',
    'stress_level',
    'hydration_level',
    'screen_time',
    'mood_level'
]

# TARGET
target = 'migraine_severity'

X = df[features]
y = df[target]

# BEFORE SMOTE
print("\n===== BEFORE SMOTE =====")
print(y.value_counts())

# APPLY SMOTE
smote = SMOTE(random_state=42)

X, y = smote.fit_resample(X, y)

# AFTER SMOTE
print("\n===== AFTER SMOTE =====")
print(y.value_counts())

# SPLIT DATA
X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.2,
    random_state=42
)

# MODELS
models = {

    "Logistic Regression": LogisticRegression(
        max_iter=1000
    ),

    "Random Forest": RandomForestClassifier(
        n_estimators=300,
        max_depth=15,
        random_state=42
    ),

    "XGBoost": XGBClassifier(
        n_estimators=300,
        max_depth=10,
        learning_rate=0.05,
        subsample=0.8,
        colsample_bytree=0.8,
        eval_metric='mlogloss',
        random_state=42
    )
}

# STORE RESULTS
results = []

# TRAIN & EVALUATE EACH MODEL
for name, model in models.items():

    print("\n====================================")
    print(f"MODEL: {name}")
    print("====================================")

    # TRAIN MODEL
    model.fit(X_train, y_train)

    # PREDICT
    y_pred = model.predict(X_test)

    # PREDICT PROBABILITIES
    y_prob = model.predict_proba(X_test)

    # MULTI-CLASS ROC-AUC
    classes = y.unique()

    y_test_bin = label_binarize(
        y_test,
        classes=classes
    )

    roc_auc = roc_auc_score(
        y_test_bin,
        y_prob,
        multi_class='ovr'
    )

    # CALCULATE METRICS
    accuracy = accuracy_score(y_test, y_pred)

    precision = precision_score(
        y_test,
        y_pred,
        average='weighted'
    )

    recall = recall_score(
        y_test,
        y_pred,
        average='weighted'
    )

    f1 = f1_score(
        y_test,
        y_pred,
        average='weighted'
    )

    # PRINT RESULTS
    print("\n===== MODEL EVALUATION =====")

    print(f"Accuracy : {accuracy:.4f}")
    print(f"Precision: {precision:.4f}")
    print(f"Recall   : {recall:.4f}")
    print(f"F1 Score : {f1:.4f}")
    print(f"ROC-AUC  : {roc_auc:.4f}")

    # CONFUSION MATRIX
    print("\n===== CONFUSION MATRIX =====")
    print(confusion_matrix(y_test, y_pred))

    # CLASSIFICATION REPORT
    print("\n===== CLASSIFICATION REPORT =====")
    print(classification_report(y_test, y_pred))

    # CROSS VALIDATION
    cv_scores = cross_val_score(
        model,
        X,
        y,
        cv=10
    )

    avg_cv = cv_scores.mean()

    print("\n===== CROSS VALIDATION =====")
    print(cv_scores)

    print(f"\nAverage Accuracy: {avg_cv:.4f}")

    # SAVE RESULTS
    results.append([
        name,
        round(accuracy, 4),
        round(precision, 4),
        round(recall, 4),
        round(f1, 4),
        round(roc_auc, 4)
    ])

# FINAL COMPARISON TABLE
print("\n\n========================================")
print("FINAL MODEL PERFORMANCE COMPARISON")
print("========================================")

print("\nModel\t\t\tAccuracy\tPrecision\tRecall\t\tF1-Score\tROC-AUC")

for r in results:

    print(
        f"{r[0]:20} "
        f"{r[1]}\t\t"
        f"{r[2]}\t\t"
        f"{r[3]}\t\t"
        f"{r[4]}\t\t"
        f"{r[5]}"
    )

# SAVE BEST MODEL (XGBOOST)
best_model = models["XGBoost"]

joblib.dump(
    best_model,
    "migraine_model.pkl"
)

print("\n✅ XGBoost model saved successfully!")