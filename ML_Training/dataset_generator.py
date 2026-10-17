"""
Hemosight (ทัศนโลหิต) - Synthetic Clinical Cohort Dataset Generator
Synthesizes realistic clinical cohort data for peripheral artery disease (PAD)
and critical limb ischemia (CLI) early screening in CKD populations.
"""

import os
import argparse
import numpy as np
import pandas as pd

def generate_cohort(n_samples=1500, random_state=42, output_csv=None):
    np.random.seed(random_state)
    
    # Stratified target classes:
    # 0 = Low Risk (45%), 1 = Moderate PAD (35%), 2 = Critical Ischemia (20%)
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
            
    # Add physiological sensor noise
    crt_seconds = np.clip(crt_seconds + np.random.normal(0, 0.15, n_samples), 0.8, 7.0).astype(np.float32)
    limb_asymmetry_pct = np.clip(limb_asymmetry_pct + np.random.normal(0, 0.5, n_samples), 0.0, 25.0).astype(np.float32)
    claudication_dist_m = np.clip(claudication_dist_m + np.random.normal(0, 15.0, n_samples), 20.0, 1000.0).astype(np.float32)
    
    df = pd.DataFrame({
        'crt_seconds': np.round(crt_seconds, 2),
        'limb_asymmetry_pct': np.round(limb_asymmetry_pct, 1),
        'rest_pain_score': rest_pain_score,
        'claudication_dist_m': np.round(claudication_dist_m, 1),
        'has_ckd_flag': has_ckd_flag,
        'risk_tier': labels
    })
    
    if output_csv:
        df.to_csv(output_csv, index=False)
        print(f"Generated {len(df)} records -> {output_csv}")
        
    return df

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate synthetic PAD/CLI clinical cohort records.")
    parser.add_argument("--samples", type=int, default=1500, help="Number of records to synthesize")
    parser.add_argument("--output", type=str, default="clinical_cohort_1500.csv", help="Target CSV output path")
    args = parser.parse_args()
    
    out_path = os.path.join(os.path.dirname(__file__), args.output)
    generate_cohort(n_samples=args.samples, output_csv=out_path)
