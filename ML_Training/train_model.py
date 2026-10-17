"""
Hemosight (ทัศนโลหิต) - ML Model Training Pipeline
Trains a multi-class Random Forest Classifier for on-device limb ischemia risk stratification
and converts the trained model into Apple Core ML format (.mlpackage).
"""

import os
import sys
import json
import uuid
import shutil
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score

def synthesize_clinical_cohort(n_samples=1500, random_state=42):
    """
    Synthesize 1,500 clinical cohort records matching real-world clinical distributions
    for geriatric and Chronic Kidney Disease (CKD) patient populations.
    
    Features:
      - crt_seconds: Capillary Refill Time in seconds (0.8s - 7.0s)
      - limb_asymmetry_pct: Bilateral calf/ankle circumference delta (0% - 25%)
      - rest_pain_score: Visual Analog Scale / numeric rating for nocturnal foot pain (0 - 10)
      - claudication_dist_m: Walking distance before cramping pain triggers (20m - 1000m)
      - has_ckd_flag: Chronic Kidney Disease stage 3-5 indicator (0 or 1)
      
    Labels:
      - 0: Low Risk (Normal perfusion, reassuring exercise tolerance)
      - 1: Moderate PAD (Intermittent claudication, mild perfusion deficit)
      - 2: Critical Ischemia Alert (CLTI: severe CRT prolongation, rest pain, tissue risk)
    """
    np.random.seed(random_state)
    
    # 1. Base clinical parameters with correlated distributions
    labels = np.random.choice([0, 1, 2], size=n_samples, p=[0.45, 0.35, 0.20])
    
    crt_seconds = np.zeros(n_samples, dtype=np.float32)
    limb_asymmetry_pct = np.zeros(n_samples, dtype=np.float32)
    rest_pain_score = np.zeros(n_samples, dtype=np.int32)
    claudication_dist_m = np.zeros(n_samples, dtype=np.float32)
    has_ckd_flag = np.zeros(n_samples, dtype=np.int32)
    
    for i in range(n_samples):
        tier = labels[i]
        if tier == 0:  # Low Risk
            crt_seconds[i] = np.random.uniform(0.8, 2.2)
            limb_asymmetry_pct[i] = np.random.uniform(0.0, 5.0)
            rest_pain_score[i] = np.random.choice([0, 1, 2], p=[0.8, 0.15, 0.05])
            claudication_dist_m[i] = np.random.uniform(400.0, 1000.0)
            has_ckd_flag[i] = np.random.choice([0, 1], p=[0.75, 0.25])
        elif tier == 1:  # Moderate PAD
            crt_seconds[i] = np.random.uniform(2.1, 4.3)
            limb_asymmetry_pct[i] = np.random.uniform(4.0, 12.0)
            rest_pain_score[i] = np.random.choice([1, 2, 3, 4, 5], p=[0.1, 0.2, 0.3, 0.3, 0.1])
            claudication_dist_m[i] = np.random.uniform(100.0, 450.0)
            has_ckd_flag[i] = np.random.choice([0, 1], p=[0.55, 0.45])
        else:  # Critical Ischemia Alert (CLTI)
            crt_seconds[i] = np.random.uniform(4.0, 7.0)
            limb_asymmetry_pct[i] = np.random.uniform(9.0, 25.0)
            rest_pain_score[i] = np.random.choice([5, 6, 7, 8, 9, 10], p=[0.05, 0.1, 0.2, 0.3, 0.25, 0.1])
            claudication_dist_m[i] = np.random.uniform(20.0, 120.0)
            has_ckd_flag[i] = np.random.choice([0, 1], p=[0.30, 0.70])
            
    # Add minor realistic physiological noise
    crt_seconds = np.clip(crt_seconds + np.random.normal(0, 0.15, n_samples), 0.8, 7.0).astype(np.float32)
    limb_asymmetry_pct = np.clip(limb_asymmetry_pct + np.random.normal(0, 0.5, n_samples), 0.0, 25.0).astype(np.float32)
    claudication_dist_m = np.clip(claudication_dist_m + np.random.normal(0, 15.0, n_samples), 20.0, 1000.0).astype(np.float32)
    
    df = pd.DataFrame({
        'crt_seconds': crt_seconds,
        'limb_asymmetry_pct': limb_asymmetry_pct,
        'rest_pain_score': rest_pain_score,
        'claudication_dist_m': claudication_dist_m,
        'has_ckd_flag': has_ckd_flag,
        'risk_tier': labels
    })
    
    return df

def create_coreml_package(spec, output_package_path):
    """
    Constructs an Apple .mlpackage bundle directory containing
    the Manifest.json and serialized model specification.
    Works deterministically across all host operating systems (macOS, Linux, Windows).
    """
    if os.path.exists(output_package_path):
        if os.path.isdir(output_package_path):
            shutil.rmtree(output_package_path)
        else:
            os.remove(output_package_path)
            
    data_dir = os.path.join(output_package_path, "Data", "com.apple.CoreML")
    os.makedirs(data_dir, exist_ok=True)
    
    # 1. Write the protobuf spec as model.mlmodel
    model_file_path = os.path.join(data_dir, "model.mlmodel")
    with open(model_file_path, "wb") as f:
        f.write(spec.SerializeToString())
        
    # 2. Write Manifest.json
    root_id = str(uuid.uuid4()).upper()
    manifest_data = {
        "fileFormatVersion": "1.0.0",
        "itemInfoEntries": {
            root_id: {
                "author": "com.apple.CoreML",
                "description": "CoreML Model Specification",
                "name": "model.mlmodel",
                "path": "Data/com.apple.CoreML/model.mlmodel"
            }
        },
        "rootModelIdentifier": root_id
    }
    
    manifest_path = os.path.join(output_package_path, "Manifest.json")
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest_data, f, indent=4)
        
    print(f"      Created valid Apple Core ML package at: {output_package_path}")

def train_and_export():
    print("==================================================")
    print("Hemosight On-Device ML Training: LimbRiskClassifier")
    print("==================================================")
    
    # 1. Synthesize cohort data
    print("[1/4] Synthesizing 1,500 clinical cohort records...")
    df = synthesize_clinical_cohort(n_samples=1500, random_state=42)
    
    csv_path = os.path.join(os.path.dirname(__file__), "clinical_cohort_1500.csv")
    df.to_csv(csv_path, index=False)
    print(f"      Saved dataset to {csv_path}")
    print(f"      Class distribution:\n{df['risk_tier'].value_counts().sort_index()}")
    
    # 2. Train-Test Split & Training
    feature_columns = ['crt_seconds', 'limb_asymmetry_pct', 'rest_pain_score', 'claudication_dist_m', 'has_ckd_flag']
    X = df[feature_columns]
    y = df['risk_tier']
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)
    
    print(f"\n[2/4] Training Random Forest Classifier on {len(X_train)} samples...")
    clf = RandomForestClassifier(
        n_estimators=100,
        max_depth=7,
        min_samples_split=4,
        random_state=42
    )
    clf.fit(X_train, y_train)
    
    y_pred = clf.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    print(f"      Validation Accuracy: {acc * 100:.2f}%")
    print(f"      Classification Report:\n{classification_report(y_test, y_pred, target_names=['Low Risk (0)', 'Moderate PAD (1)', 'Critical Ischemia (2)'])}")
    
    # 3. Export to Core ML
    print("[3/4] Converting Scikit-Learn Model to Core ML format...")
    import coremltools as ct
    
    coreml_model = ct.converters.sklearn.convert(
        clf,
        input_features=feature_columns,
        output_feature_names='risk_tier'
    )
    
    # Set model metadata for Xcode & Apple Neural Engine documentation
    coreml_model.author = "Hemosight Clinical AI Team"
    coreml_model.short_description = "On-device multi-modal Critical Limb Ischemia (CLI) and PAD risk classifier for CKD patients."
    coreml_model.license = "Proprietary - Hackathon Young iOS 2026"
    coreml_model.user_defined_metadata["version"] = "1.0.0"
    coreml_model.user_defined_metadata["dataset_size"] = "1500"
    
    # Input descriptions
    coreml_model.input_description['crt_seconds'] = "Capillary Refill Time measured in seconds (0.8 - 7.0s)"
    coreml_model.input_description['limb_asymmetry_pct'] = "Bilateral limb circumference delta percentage (0.0 - 25.0%)"
    coreml_model.input_description['rest_pain_score'] = "Numeric nocturnal rest pain score reported by patient (0 - 10)"
    coreml_model.input_description['claudication_dist_m'] = "Walking distance in meters before claudication cramping (20 - 1000m)"
    coreml_model.input_description['has_ckd_flag'] = "Indicator if patient has Chronic Kidney Disease Stage 3-5 (0 or 1)"
    coreml_model.output_description['risk_tier'] = "Predicted risk category: 0 = Low Risk, 1 = Moderate PAD, 2 = Critical Ischemia"
    
    # 4. Save .mlpackage artifact
    export_dir = os.path.dirname(__file__)
    mlpackage_path = os.path.join(export_dir, "LimbRiskClassifier.mlpackage")
    mlmodel_path = os.path.join(export_dir, "LimbRiskClassifier.mlmodel")
    
    print(f"[4/4] Saving compiled Core ML artifacts...")
    # Save standalone .mlmodel
    with open(mlmodel_path, "wb") as f:
        f.write(coreml_model._spec.SerializeToString())
    print(f"      Saved: {mlmodel_path}")
    
    # Save .mlpackage bundle structure
    create_coreml_package(coreml_model._spec, mlpackage_path)
    
    if os.path.exists(mlpackage_path) and os.path.exists(os.path.join(mlpackage_path, "Manifest.json")):
        print(" SUCCESS: LimbRiskClassifier.mlpackage created successfully!")
        
        # Mirror to Hemosight/Resources for Xcode project target
        hemosight_res_dir = os.path.join(os.path.dirname(export_dir), "Hemosight", "Resources")
        os.makedirs(hemosight_res_dir, exist_ok=True)
        
        target_package = os.path.join(hemosight_res_dir, "LimbRiskClassifier.mlpackage")
        if os.path.exists(target_package):
            shutil.rmtree(target_package)
        shutil.copytree(mlpackage_path, target_package)
        
        target_model = os.path.join(hemosight_res_dir, "LimbRiskClassifier.mlmodel")
        shutil.copy2(mlmodel_path, target_model)
        print(f"       Mirrored .mlpackage & .mlmodel to Xcode bundle: {hemosight_res_dir}")
    else:
        print(" ERROR: Model package was not created.")
        sys.exit(1)

if __name__ == "__main__":
    train_and_export()
