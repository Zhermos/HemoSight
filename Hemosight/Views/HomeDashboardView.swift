import SwiftUI

/// Primary navigation dashboard adhering to modern Apple Human Interface Guidelines (HIG).
/// Displays quick scan action cards, clinical contrast warning alerts,
/// multi-modal completion status, and recent diagnostic history.
public struct HomeDashboardView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var showingCRTScan = false
    @State private var showingLiDARScan = false
    @State private var showingQuestionnaire = false
    @State private var showingReport = false
    @State private var showingPatientPicker = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Patient Header & Nephrology Alert
                    patientHeaderCard
                    
                    if appState.currentPatient.hasCKD {
                        contrastSafetyBanner
                    }
                    
                    // MARK: - Multi-Modal Sensor Action Cards
                    sensorActionsSection
                    
                    // MARK: - Triage Evaluation Launcher
                    evaluationActionButton
                    
                    // MARK: - Diagnostic History
                    if !appState.historicalReports.isEmpty {
                        recentHistorySection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(red: 0.07, green: 0.08, blue: 0.10).ignoresSafeArea())
            .navigationTitle("Hemosight (ทัศนโลหิต)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundColor(.red)
                        Text("On-Device CLI AI")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingPatientPicker = true
                    } label: {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingCRTScan) {
                CRTScanView()
            }
            .sheet(isPresented: $showingLiDARScan) {
                LiDARScanView()
            }
            .sheet(isPresented: $showingQuestionnaire) {
                QuestionnaireView()
            }
            .sheet(isPresented: $showingReport) {
                if let report = appState.currentReport {
                    RiskReportView(report: report)
                }
            }
            .confirmationDialog("Select Patient Profile", isPresented: $showingPatientPicker) {
                Button("Grandma Somchai (CKD Stage 4 + Severe Rest Pain)") {
                    appState.currentPatient = PatientProfile.elderlyDialysisPatient
                }
                Button("Healthy Volunteer Cohort") {
                    appState.currentPatient = PatientProfile.standardHealthyAdult
                }
                Button("Custom Clinical Case") {
                    showingQuestionnaire = true
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
    
    // MARK: - UI Components
    
    private var patientHeaderCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: "person.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(appState.currentPatient.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text("Age: \(appState.currentPatient.age)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(appState.currentPatient.hasCKD ? "CKD Stage 3–5" : "Normal Renal Function")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(appState.currentPatient.hasCKD ? Color.purple.opacity(0.3) : Color.green.opacity(0.2))
                        .foregroundColor(appState.currentPatient.hasCKD ? .purple : .green)
                        .cornerRadius(4)
                }
            }
            Spacer()
            
            Button {
                showingQuestionnaire = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.secondary)
                    .padding(8)
            }
        }
        .padding(14)
        .background(Color(red: 0.12, green: 0.13, blue: 0.16))
        .cornerRadius(14)
    }
    
    private var contrastSafetyBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Contrast-Induced Nephropathy (CIN) Caution")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                Text("Standard angiography contrast is contraindicated. Hemosight delivers 100% optical + LiDAR non-invasive microvascular screening.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(2)
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.4), lineWidth: 1)
        )
        .cornerRadius(12)
    }
    
    private var sensorActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Multi-Modal Screening Sensors")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Sensor 1: Digital CRT
                SensorCard(
                    title: "Digital Capillary Refill Time (CRT)",
                    subtitle: "60 FPS nailbed blanching & perfusion curve",
                    icon: "drop.fill",
                    accentColor: .red,
                    isCompleted: appState.currentCRT != nil,
                    statusText: appState.currentCRT != nil ? "\(appState.currentCRT!.formattedCRT) (\(appState.currentCRT!.clinicalTier.localizedName))" : "Not Scanned"
                ) {
                    showingCRTScan = true
                }
                
                // Sensor 2: LiDAR Morphometry
                SensorCard(
                    title: "ARKit 3D LiDAR Morphometry",
                    subtitle: "Calf circumference & atrophy asymmetry",
                    icon: "camera.metering.matrix",
                    accentColor: .blue,
                    isCompleted: appState.currentLimbScan != nil,
                    statusText: appState.currentLimbScan != nil ? "Δ \(String(format: "%.1f%%", appState.currentLimbScan!.calfAsymmetryPct)) Asymmetry" : "Not Scanned"
                ) {
                    showingLiDARScan = true
                }
                
                // Sensor 3: Clinical Questionnaire
                SensorCard(
                    title: "Symptoms & Rest Pain Questionnaire",
                    subtitle: "Nocturnal rest pain & claudication walking limit",
                    icon: "list.clipboard.fill",
                    accentColor: .purple,
                    isCompleted: true,
                    statusText: "Pain: \(appState.currentPatient.restPainScore)/10 • Walking: \(Int(appState.currentPatient.claudicationDistanceMeters))m"
                ) {
                    showingQuestionnaire = true
                }
            }
        }
    }
    
    private var evaluationActionButton: some View {
        Button {
            let report = appState.runEvaluation()
            showingReport = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "cpu")
                    .font(.headline)
                Text("Run On-Device ML Risk Evaluation")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color(red: 0.1, green: 0.4, blue: 0.9)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(14)
            .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .padding(.top, 4)
    }
    
    private var recentHistorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Previous Screenings")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(appState.historicalReports) { report in
                Button {
                    appState.currentReport = report
                    showingReport = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: report.riskTier.iconName)
                            .font(.title2)
                            .foregroundColor(Color(hex: report.riskTier.colorHex))
                            .frame(width: 36)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(report.riskTier.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Text(report.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(Int(report.confidenceScore * 100))% Conf.")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color(red: 0.12, green: 0.13, blue: 0.16))
                    .cornerRadius(12)
                }
            }
        }
        .padding(.top, 10)
    }
}

// MARK: - Sensor Action Card Component

private struct SensorCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let isCompleted: Bool
    let statusText: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accentColor.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.headline)
                        .foregroundColor(accentColor)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isCompleted ? Color.green : Color.gray)
                            .frame(width: 6, height: 6)
                        Text(statusText)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(isCompleted ? .green : .secondary)
                    }
                    .padding(.top, 2)
                }
                
                Spacer()
                
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "chevron.right")
                    .foregroundColor(isCompleted ? .green : .secondary)
            }
            .padding(12)
            .background(Color(red: 0.12, green: 0.13, blue: 0.16))
            .cornerRadius(12)
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
