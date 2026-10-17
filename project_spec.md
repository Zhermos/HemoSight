# Hemosight (ทัศนโลหิต) - Project Specification

**On-Device Critical Limb Ischemia & Peripheral Artery Disease Early-Screening for High-Risk & Kidney Patients**  
*Hackathon Young iOS 2026 (48-Hour Rapid Prototype Track)*

---

## 1. Executive Summary & Problem Statement

### 1.1 The Clinical Dilemma
Peripheral Artery Disease (PAD) and Critical Limb Ischemia (CLI) are leading causes of non-traumatic lower-extremity amputations worldwide. In elderly individuals and patients suffering from Chronic Kidney Disease (CKD), clinical diagnosis presents a severe dilemma:
- **Contrast-Induced Nephropathy (CIN):** Standard angiography (ฉีดสี) requires iodinated or gadolinium contrast agents, which are severely nephrotoxic. In stage 3–5 CKD patients or nonagenarians, contrast injection frequently precipitates acute renal failure requiring permanent hemodialysis.
- **The "Old Age" Bias & Delayed Detection:** Early ischemic signs—rest pain (*ปวดขาเวลานอน*), exercise-induced claudication (*ปวดน่องเวลาเดิน*), and microvascular pallor—are routinely misattributed to common geriatric aches. By the time tissue necrosis or gangrene becomes clinically obvious, surgical amputation is the only remaining option.

### 1.2 The Hemosight Solution
**Hemosight** is an on-device iOS application designed for iPhone/iPad Pro models. It leverages consumer optical and spatial sensors (Camera + Torch + LiDAR) alongside On-Device Machine Learning (Core ML) to provide:
1. **100% Non-Invasive & Contrast-Free Screening:** Zero radiation, zero chemical injections, completely safe for dialysis and pre-dialysis patients.
2. **Digital Capillary Refill Time (CRT):** Quantitative microvascular perfusion assessment via real-time red-spectrum intensity recovery curves.
3. **Bilateral 3D Limb Morphometry:** High-precision circumference and volume asymmetry tracking via ARKit LiDAR scanning to identify ischemic muscle atrophy and unilateral edema.
4. **On-Device Multi-Modal Risk Scoring:** A custom machine learning classifier executed entirely on the Apple Neural Engine (ANE) to protect sensitive biometric data.

---

## 2. Technical Stack & Sensor Architecture

### 2.1 Hardware Requirements
- **Primary Target:** iPhone 12 Pro through iPhone 17 Pro / iPad Pro (devices equipped with LiDAR Scanner).
- **Secondary Target (Limited Mode):** Standard iPhones supporting AVFoundation Camera + Torch (CRT only, excluding 3D mesh).

### 2.2 Frameworks & Libraries
- **Language:** Swift 5.10 / Swift 6 (Strict Concurrency Checking).
- **UI Framework:** SwiftUI with Swift Charts for real-time physiological waveform rendering.
- **Sensor Drivers:**
  - `AVFoundation`: High-frame-rate pixel buffer streaming, locked focus/exposure, continuous torch control.
  - `ARKit` & `RealityKit`: Direct Time-of-Flight (dToF) depth sensing, scene reconstruction mesh extraction.
- **Machine Learning & Vision:**
  - `Core ML`: On-device inference powered by Apple Neural Engine (ANE).
  - `Vision`: Automatic detection and tracking of the toe nailbed region of interest (ROI).
  - `Accelerate` (vDSP): Real-time Fast Fourier Transform (FFT) and moving-average noise filtering for perfusion curves.

---

## 3. System Architecture & Directory Layout

```
Hemosight/
├── PROJECT_SPEC.md                      # Master Blueprint & Architecture Document
├── ML_Training/
│   ├── dataset_generator.py             # Synthetic clinical cohort data synthesizer
│   ├── train_model.py                   # Model training script (Scikit-Learn / PyTorch)
│   └── LimbRiskClassifier.mlpackage     # Compiled Core ML model artifact
├── Hemosight/
│   ├── App/
│   │   └── HemosightApp.swift           # Main Application Lifecycle & Navigation Stack
│   ├── Models/
│   │   ├── CRTMeasurement.swift         # Data structures for perfusion & time-series curves
│   │   ├── LimbScanData.swift           # 3D mesh metrics, circumference, and volume deltas
│   │   ├── PatientProfile.swift         # Medical history flags (CKD stage, diabetes, smoking)
│   │   └── RiskReport.swift             # Multi-modal risk tier (Low / Moderate / Critical)
│   ├── Core/
│   │   ├── CRTCameraManager.swift       # Camera session, torch lock, and RGB pixel extractor
│   │   ├── PerfusionSignalProcessor.swift# Peak detection, baseline drift removal, CRT calculator
│   │   ├── LiDARScanner.swift           # ARKit session, point cloud slice, and circumference logic
│   │   └── RiskEvaluator.swift          # Core ML wrapper combining physical and clinical metrics
│   ├── Views/
│   │   ├── HomeDashboardView.swift      # Main navigation, previous history, quick scan launcher
│   │   ├── CRTScanView.swift            # Interactive camera view with live perfusion waveform
│   │   ├── LiDARScanView.swift          # 3D augmented reality leg scanning interface
│   │   ├── QuestionnaireView.swift      # Edinburgh Claudication & Rest Pain assessment form
│   │   └── RiskReportView.swift         # Color-coded triage card & printable clinician PDF export
│   └── Resources/
│       ├── Assets.xcassets              # App icons, color tokens, and anatomical guides
│       └── Info.plist                   # Camera and LiDAR privacy descriptions
```

---

## 4. Module Specifications

### 4.1 Module 1: Digital Capillary Refill Time (CRT) Engine
- **Clinical Target:** Microvascular capillary reperfusion speed following blanching pressure.
- **Procedure:**
  1. The user positions the iPhone camera 5–10 cm above the patient's great toe (*นิ้วโป้งเท้า*).
  2. The flash torch illuminates the nailbed at a constant lux level.
  3. The caregiver applies steady pressure for 3 seconds until blanched, then releases.
  4. The camera captures video at 60 FPS in 1080p format.
- **Signal Extraction:**
  - The mean red-channel intensity $I_R(t)$ is computed for each frame:
    $$\bar{I}_R(t) = \frac{1}{N} \sum_{(x,y) \in \text{ROI}} R(x,y,t)$$
  - Baseline recovery threshold: The time required for $I_R(t)$ to transition from minimum reflectance $I_{\min}$ back to $90\%$ of pre-compression baseline $I_{\text{base}}$:
    $$\text{CRT} = t_{90\%} - t_{\text{release}}$$
- **Clinical Triage Thresholds:**
  - **Normal:** $\text{CRT} < 2.0\text{ s}$
  - **Borderline / Mild Ischemia:** $2.0\text{ s} \le \text{CRT} \le 4.0\text{ s}$
  - **Critical Limb-Threatening Ischemia (CLTI):** $\text{CRT} > 4.5\text{ s}$

### 4.2 Module 2: LiDAR Lower Limb Morphometry Engine
- **Clinical Target:** Quantifying limb circumference asymmetry and muscular atrophy caused by chronic arterial occlusion.
- **Procedure:**
  1. The user scans both lower limbs in a single sweeping arc from ankle to mid-calf.
  2. ARKit extracts horizontal planar slices at 2 landmark elevations: Ankle (malleolus level) and Maximum Calf Girth.
  3. Convex-hull or boundary polygon integration computes circumference $C_{\text{left}}, C_{\text{right}}$.
- **Asymmetry Formula:**
  $$\Delta C = \frac{|C_{\text{affected}} - C_{\text{contralateral}}|}{C_{\text{contralateral}}} \times 100\%$$
- **Clinical Triage Thresholds:**
  - $\Delta C > 8.0\%$ at the calf indicates marked unilateral ischemic muscle wasting or secondary lymphedema/DVT.

### 4.3 Module 3: Custom On-Device ML Risk Classifier
- **Model Type:** Multi-Class Gradient Boosted Decision Tree / Random Forest.
- **Input Features (Vector of 5 Dimensions):**
  1. `crt_seconds` (Float, continuous): Digital CRT duration.
  2. `limb_asymmetry_pct` (Float, continuous): Circumference delta between legs.
  3. `rest_pain_score` (Int, 0–10): Patient-reported nocturnal foot pain intensity.
  4. `claudication_distance_m` (Float): Walking distance before calf cramp triggers.
  5. `has_ckd_flag` (Int, 0 or 1): Patient pre-existing renal insufficiency indicator.
- **Target Classes:**
  - `0: Low Risk` (Reassurance & routine physical activity).
  - `1: Moderate PAD` (Non-urgent outpatient vascular consultation recommended).
  - `2: Critical Ischemia Alert` (Immediate Doppler Ultrasound referral; urgent hospital admission).

---

## 5. Development Timeline (48-Hour Hackathon Breakdown)

| Time Window | Milestone & Deliverable | Primary Tool / Subagent |
| :--- | :--- | :--- |
| **Hours 00–06** | Architecture lock, Data models, Synthetic ML dataset & model training | Python on Windows (`coremltools`) |
| **Hours 06–18** | Sensor drivers: Camera CRT signal extractor & ARKit LiDAR slice logic | Antigravity Specialist Agents |
| **Hours 18–30** | SwiftUI UI construction: Real-time waveform, 3D mesh visualizer, Report card | Antigravity SwiftUI Specialist |
| **Hours 30–38** | End-to-end integration, Git push to Mac, Xcode build verification on iPhone Pro | Xcode on macOS (via Git) |
| **Hours 38–44** | Real-world simulation testing (toe blanching live test, ankle asymmetry bandage demo) | Live Device Testing |
| **Hours 44–48** | Pitch deck refinement (Grandma case study), 3-minute stage presentation rehearsal | Pitch Coach Subagent |

---

## 6. Antigravity Automate Workflow Execution Plan

When running the autonomous implementation workflow within Google Antigravity, execute the following prompt sequence:

### Step 1: Scaffolding & Shared Data Types
> *"Read `PROJECT_SPEC.md`. Create `CRTMeasurement.swift`, `LimbScanData.swift`, and `RiskReport.swift` under `Hemosight/Models/`. Ensure all models conform to `Identifiable`, `Codable`, and `Sendable`."*

### Step 2: Signal Processing & Camera Module
> *"Implement `CRTCameraManager.swift` and `PerfusionSignalProcessor.swift` under `Hemosight/Core/`. Configure `AVCaptureSession` with high framerate, active torch, and frame-by-frame pixel buffer analysis to calculate CRT in seconds."*

### Step 3: LiDAR 3D Measurement Module
> *"Implement `LiDARScanner.swift` using ARKit `ARWorldTrackingConfiguration` with `.meshWithClassification`. Provide functions to compute cross-sectional circumference of lower leg slices."*

### Step 4: SwiftUI Dashboard & Report Card
> *"Implement `ContentView.swift` and `RiskReportView.swift` in SwiftUI. Connect the sensor managers to reactive state objects and display risk alerts with actionable medical recommendations."*
