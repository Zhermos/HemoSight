# Hemosight (ทัศนโลหิต)
**On-Device Critical Limb Ischemia & Peripheral Artery Disease Early-Screening for High-Risk & Kidney Patients**  
*Hackathon Young iOS 2026 (48-Hour Rapid Prototype Track)*

---

## 1. Overview & Clinical Rationale
Peripheral Artery Disease (PAD) and Critical Limb Ischemia (CLI / CLTI) are major causes of preventable lower-limb amputations. In geriatric and Chronic Kidney Disease (CKD) populations, standard diagnosis faces a severe obstacle:
- **Contrast-Induced Nephropathy (CIN):** Standard iodinated/gadolinium angiography dyes cause severe acute renal injury in patients with eGFR < 60 mL/min or on dialysis.
- **The "Old Age" Bias:** Rest pain (*ปวดเท้าเวลานอน*) and intermittent claudication (*ปวดน่องเวลาเดิน*) are frequently dismissed until gangrene or ulcers manifest.

**Hemosight** solves this dilemma by turning standard Apple hardware sensors (Camera + Torch + LiDAR) into a **100% non-invasive, contrast-free clinical screening workstation**, powered by on-device Machine Learning via Core ML and Apple Neural Engine (ANE).

---

## 2. Key Modules & Technology Stack

### Module 1: Digital Capillary Refill Time (CRT)
- **Engine:** `Hemosight/Core/CRTCameraManager.swift` + `Hemosight/Core/PerfusionSignalProcessor.swift`
- **Sensors:** 60 FPS 1080p camera with locked continuous torch illumination.
- **Signal Extraction:** Central nailbed region-of-interest (ROI) mean red-intensity extraction:
  $$\bar{I}_R(t) = \frac{1}{N}\sum_{(x,y) \in \text{ROI}} R(x,y,t)$$
- **Recovery Threshold:** Time elapsed from release nadir $I_{\min}$ to $90\%$ of baseline $I_{\text{base}}$:
  $$\text{CRT} = t_{90\%} - t_{\text{release}}$$
- **Triage:** Normal ($<2.0\text{s}$), Borderline ($2.0\text{–}4.0\text{s}$), Critical Ischemia ($>4.5\text{s}$).

### Module 2: 3D LiDAR Morphometry & Asymmetry
- **Engine:** `Hemosight/Core/LiDARScanner.swift`
- **Sensors:** ARKit `ARWorldTrackingConfiguration` with `.meshWithClassification`.
- **Morphometry:** Real-time horizontal planar slicing across ankle and calf elevations, calculating bilateral circumference $C_{\text{left}}, C_{\text{right}}$.
- **Diagnostic Asymmetry:**
  $$\Delta C = \frac{|C_{\text{affected}} - C_{\text{contralateral}}|}{\max(C_{\text{left}}, C_{\text{right}})} \times 100\%$$
  Delta $> 8.0\%$ flags ischemic muscle wasting or unilateral edema.

### Module 3: On-Device Machine Learning Classifier
- **Model:** `LimbRiskClassifier.mlpackage` & `LimbRiskClassifier.mlmodel`
- **Inputs:** 5 multimodal features (`crt_seconds`, `limb_asymmetry_pct`, `rest_pain_score`, `claudication_dist_m`, `has_ckd_flag`).
- **Target Tiers:**
  - `0: Low Risk` (Reassurance, supervised walking exercise)
  - `1: Moderate PAD` (Outpatient vascular consultation, non-urgent duplex ultrasound)
  - `2: Critical Ischemia Alert (CLTI)` (Urgent bedside Doppler, emergency vascular referral)
- **Inference:** Apple Neural Engine (ANE) with instant clinical rule engine fallback.

---

## 3. Directory Layout

```
HemoSight/
├── project_spec.md                      # Master Blueprint & Architecture Document
├── README.md                            # Project Documentation
├── ML_Training/
│   ├── dataset_generator.py             # Synthetic cohort generator (1,500 records)
│   ├── train_model.py                   # Random Forest trainer & Core ML exporter
│   ├── clinical_cohort_1500.csv         # Synthesized cohort data
│   ├── LimbRiskClassifier.mlmodel       # Serialized Core ML Model
│   └── LimbRiskClassifier.mlpackage/    # Apple Core ML Package bundle
├── Hemosight/
│   ├── App/
│   │   └── HemosightApp.swift           # App Lifecycle & Global Reactive AppState
│   ├── Models/
│   │   ├── CRTMeasurement.swift         # Perfusion waveform & CRT metrics
│   │   ├── LimbScanData.swift           # 3D LiDAR bilateral circumference & delta
│   │   ├── PatientProfile.swift         # Demographics, CKD, rest pain, claudication
│   │   └── RiskReport.swift             # Multimodal risk report & recommendations
│   ├── Core/
│   │   ├── CRTCameraManager.swift       # 60 FPS AVFoundation camera & torch driver
│   │   ├── PerfusionSignalProcessor.swift# Accelerate/vDSP moving-average & CRT logic
│   │   ├── LiDARScanner.swift           # ARKit mesh slicing & cross-section calculator
│   │   └── RiskEvaluator.swift          # Core ML / ANE inference & clinical engine
│   ├── Views/
│   │   ├── HomeDashboardView.swift      # Modern HIG Dashboard & CIN alert banner
│   │   ├── CRTScanView.swift            # Viewfinder with Swift Charts perfusion graph
│   │   ├── LiDARScanView.swift          # 3D ARKit scanning & circumference readout
│   │   ├── QuestionnaireView.swift      # Rest pain & walking tolerance assessment
│   │   └── RiskReportView.swift         # Medical triage card & clinician report export
│   └── Resources/
│       ├── Info.plist                   # Camera & LiDAR privacy descriptions
│       ├── LimbRiskClassifier.mlmodel   # Core ML model asset for Xcode bundle
│       └── LimbRiskClassifier.mlpackage/# Core ML package bundle for Xcode target
```

---

## 4. How to Run & Verify

### Step 1: Retrain Machine Learning Model (Optional)
```bash
python ML_Training/train_model.py
```

### Step 2: Open in Xcode
1. Create or open an iOS Project in Xcode (Target: iOS 17.0+).
2. Add the `Hemosight/` folder to the Xcode project.
3. Ensure `Info.plist` is linked to provide `NSCameraUsageDescription` and `NSWorldSensingUsageDescription`.
4. Build and deploy to iPhone 12 Pro–17 Pro or iPad Pro with LiDAR.
5. In Xcode Simulator or Mac Catalyst, automatic simulation fallback drivers provide live interactive testing without physical camera/LiDAR hardware.