import SwiftUI
import Combine

/// Minimalist, Apple Health-inspired Home Dashboard for Hemosight.
/// Built strictly following `swiftui-pro` standards:
/// - Uses modern `foregroundStyle()` and `clipShape(.rect(cornerRadius:))`
/// - Applies `.scrollIndicators(.hidden)` and semantic toolbars
/// - Enforces 44x44 minimum tap areas, Dynamic Type, and sensory feedback
/// - Leverages `#Preview`
public struct HomeDashboardView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var showingCRTScan = false
    @State private var showingLiDARScan = false
    @State private var showingQuestionnaire = false
    @State private var showingReport = false
    @State private var showingPatientPicker = false
    
    public init() {}
    
    private var completedStepCount: Int {
        var count = 0
        if appState.currentCRT != nil { count += 1 }
        if appState.currentLimbScan != nil { count += 1 }
        count += 1 // Questionnaire is pre-populated
        return count
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Patient Header & Zero-Contrast Badge
                    patientHeaderSection
                    
                    // Hero Title & Progress
                    heroHeaderSection
                    
                    // 3-Step Guided Screening Cards
                    stepsSection
                    
                    // Primary Action
                    analyzeButton
                    
                    // Historical Screenings
                    if !appState.historicalReports.isEmpty {
                        historySection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .background(Color(red: 0.04, green: 0.04, blue: 0.06).ignoresSafeArea())
            .navigationTitle("Hemosight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Label("Non-Invasive CLI Screening", systemImage: "waveform.path.ecg")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Switch Patient Profile", systemImage: "person.crop.circle.badge.plus") {
                        showingPatientPicker = true
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.tint)
                    .frame(minWidth: 44, minHeight: 44)
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
    
    // MARK: - Subviews
    
    private var patientHeaderSection: some View {
        HStack {
            Button {
                showingPatientPicker = true
            } label: {
                HStack(spacing: 8) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                    Text(appState.currentPatient.name)
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.white)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
            }
            .frame(minHeight: 44)
            
            Spacer()
            
            Label(appState.currentPatient.hasCKD ? "CIN Safe" : "Non-Invasive", systemImage: "shield.checkered")
                .font(.caption)
                .bold()
                .foregroundStyle(appState.currentPatient.hasCKD ? Color.purple : Color.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background((appState.currentPatient.hasCKD ? Color.purple : Color.green).opacity(0.12))
                .clipShape(Capsule())
        }
    }
    
    private var heroHeaderSection: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hemosight")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("On-Device Limb Ischemia Screening")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(completedStepCount)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("/3")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.06))
            .clipShape(.rect(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var stepsSection: some View {
        VStack(spacing: 12) {
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
    
    private var analyzeButton: some View {
        Button {
            let report = appState.runEvaluation()
            showingReport = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "cpu")
                    .font(.headline)
                Text("Analyze Limb Risk")
                    .font(.headline)
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.15, green: 0.45, blue: 1.0), Color(red: 0.05, green: 0.30, blue: 0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 18))
            .shadow(color: Color.blue.opacity(0.35), radius: 12, x: 0, y: 5)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: showingReport)
        .padding(.top, 4)
    }
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Previous Screenings")
                .font(.footnote)
                .bold()
                .foregroundStyle(.secondary)
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
                                .font(.subheadline)
                                .bold()
                                .foregroundStyle(.white)
                            Text(report.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(report.confidenceScore * 100))% Conf.")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.secondary)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(minHeight: 44)
                    .background(Color.white.opacity(0.04))
                    .clipShape(.rect(cornerRadius: 16))
                }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Minimal Step Card

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
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .bold()
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Text(statusValue)
                        .font(.footnote)
                        .bold()
                        .foregroundStyle(isCompleted ? .white : .secondary)
                    
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(isCompleted ? .green : .secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(minHeight: 64)
            .background(Color.white.opacity(0.05))
            .clipShape(.rect(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isCompleted ? accentColor.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1)
            }
        }
        .frame(minHeight: 44)
    }
}

#Preview {
    HomeDashboardView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
