import SwiftUI
import Combine

/// Minimalist, Apple Health-inspired Home Dashboard for Hemosight (ทัศนโลหิต).
/// Features a streamlined 3-step screening workflow, high-contrast typography,
/// non-invasive contrast-safety indicators, and instant on-device evaluation.
public struct HomeDashboardView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var showingCRTScan = false
    @State private var showingLiDARScan = false
    @State private var showingQuestionnaire = false
    @State private var showingReport = false
    @State private var showingPatientPicker = false
    
    public init() {}
    
    // Computed completion count (0 to 3)
    private var completedStepCount: Int {
        var count = 0
        if appState.currentCRT != nil { count += 1 }
        if appState.currentLimbScan != nil { count += 1 }
        count += 1 // Questionnaire is pre-populated
        return count
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // MARK: - Patient Capsule & Zero-Contrast Badge
                    topStatusHeader
                    
                    // MARK: - Hero Progress & Title
                    heroHeader
                    
                    // MARK: - Minimal 3-Step Screening Cards
                    screeningStepsSection
                    
                    // MARK: - Primary Action Button
                    evaluateButton
                    
                    // MARK: - Recent Screenings (if any)
                    if !appState.historicalReports.isEmpty {
                        recentHistorySection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(red: 0.04, green: 0.04, blue: 0.06).ignoresSafeArea())
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
            .confirmationDialog("Switch Patient Profile", isPresented: $showingPatientPicker) {
                Button("Grandma Somchai (CKD Stage 4 / CLTI High Risk)") {
                    appState.currentPatient = PatientProfile.elderlyDialysisPatient
                }
                Button("Healthy Volunteer Cohort") {
                    appState.currentPatient = PatientProfile.standardHealthyAdult
                }
                Button("Custom Clinical Case...") {
                    showingQuestionnaire = true
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
    
    // MARK: - Top Status Header
    
    private var topStatusHeader: some View {
        HStack {
            // Patient selector capsule
            Button {
                showingPatientPicker = true
            } label: {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    Text(appState.currentPatient.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
            }
            
            Spacer()
            
            // Contrast safety badge
            HStack(spacing: 5) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(appState.currentPatient.hasCKD ? .purple : .green)
                Text(appState.currentPatient.hasCKD ? "CIN Safe" : "Non-Invasive")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(appState.currentPatient.hasCKD ? .purple : .green)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background((appState.currentPatient.hasCKD ? Color.purple : Color.green).opacity(0.12))
            .clipShape(Capsule())
        }
    }
    
    // MARK: - Hero Header
    
    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hemosight")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("Limb Ischemia Screening")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                // Progress Counter
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(completedStepCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("/3")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - 3-Step Screening Cards
    
    private var screeningStepsSection: some View {
        VStack(spacing: 12) {
            // Step 1: CRT Perfusion
            MinimalStepCard(
                stepNumber: "1",
                title: "Capillary Refill (CRT)",
                subtitle: "60 FPS nailbed blanching curve",
                icon: "drop.fill",
                accentColor: .red,
                isCompleted: appState.currentCRT != nil,
                statusValue: appState.currentCRT != nil ? appState.currentCRT!.formattedCRT : "Tap to scan"
            ) {
                showingCRTScan = true
            }
            
            // Step 2: 3D LiDAR Morphometry
            MinimalStepCard(
                stepNumber: "2",
                title: "3D Limb Morphometry",
                subtitle: "Bilateral calf & ankle asymmetry",
                icon: "camera.metering.matrix",
                accentColor: .blue,
                isCompleted: appState.currentLimbScan != nil,
                statusValue: appState.currentLimbScan != nil ? String(format: "Δ %.1f%%", appState.currentLimbScan!.calfAsymmetryPct) : "Tap to scan"
            ) {
                showingLiDARScan = true
            }
            
            // Step 3: Symptoms & Pain Questionnaire
            MinimalStepCard(
                stepNumber: "3",
                title: "Clinical Symptoms",
                subtitle: "Rest pain score & walking limit",
                icon: "list.clipboard.fill",
                accentColor: .purple,
                isCompleted: true,
                statusValue: "Pain \(appState.currentPatient.restPainScore)/10 • \(Int(appState.currentPatient.claudicationDistanceMeters))m"
            ) {
                showingQuestionnaire = true
            }
        }
    }
    
    // MARK: - Evaluate Button
    
    private var evaluateButton: some View {
        Button {
            let report = appState.runEvaluation()
            showingReport = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "cpu")
                    .font(.system(size: 17, weight: .semibold))
                Text("Analyze Limb Risk")
                    .font(.system(size: 17, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.15, green: 0.45, blue: 1.0), Color(red: 0.05, green: 0.30, blue: 0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.blue.opacity(0.35), radius: 14, x: 0, y: 6)
        }
        .padding(.top, 4)
    }
    
    // MARK: - Recent History Section
    
    private var recentHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Previous Screenings")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)
            
            ForEach(appState.historicalReports) { report in
                Button {
                    appState.currentReport = report
                    showingReport = true
                } label: {
                    HStack(spacing: 14) {
                        Circle()
                            .fill(Color(hex: report.riskTier.colorHex))
                            .frame(width: 10, height: 10)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(report.riskTier.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            Text(report.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(report.confidenceScore * 100))% Conf.")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Minimal Step Card Component

private struct MinimalStepCard: View {
    let stepNumber: String
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let isCompleted: Bool
    let statusValue: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Circular icon
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(accentColor)
                }
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status pill / checkmark
                HStack(spacing: 6) {
                    Text(statusValue)
                        .font(.system(size: 12, weight: isCompleted ? .semibold : .medium))
                        .foregroundColor(isCompleted ? .white : .secondary)
                    
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(isCompleted ? .green : .secondary.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isCompleted ? accentColor.opacity(0.25) : Color.white.opacity(0.06), lineWidth: 1)
            )
        }
    }
}

// MARK: - Color Hex Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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
