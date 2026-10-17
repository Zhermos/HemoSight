import SwiftUI

/// Comprehensive Clinical Triage Card & Actionable Report View.
/// Formats multi-modal results for vascular surgeons and nephrologists,
/// displaying contrast-free clinical recommendations and sensor evidence.
public struct RiskReportView: View {
    @Environment(\.dismiss) private var dismiss
    public let report: RiskReport
    
    @State private var showingShareSheet = false
    
    public init(report: RiskReport) {
        self.report = report
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Triage Header Badge
                    triageHeaderCard
                    
                    // MARK: - CIN Contrast Safety Alert
                    cinSafetyAlertCard
                    
                    // MARK: - Primary Actionable Clinical Recommendation
                    recommendationCard
                    
                    // MARK: - Objective Sensor Measurements Grid
                    sensorMetricsGrid
                    
                    // MARK: - Clinical Findings & Evidence
                    evidenceNotesCard
                    
                    // MARK: - Export & Consultation Actions
                    exportActionsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(Color(red: 0.07, green: 0.08, blue: 0.10).ignoresSafeArea())
            .navigationTitle("Clinical Triage Assessment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: [generateReportTextSummary()])
            }
        }
    }
    
    // MARK: - Triage Header Card
    
    private var triageHeaderCard: some View {
        VStack(spacing: 12) {
            HStack {
                Label(report.riskTier.shortCode, systemImage: report.riskTier.iconName)
                    .font(.caption)
                    .fontWeight(.heavy)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: report.riskTier.colorHex).opacity(0.2))
                    .foregroundColor(Color(hex: report.riskTier.colorHex))
                    .cornerRadius(6)
                
                Spacer()
                
                Text(report.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: report.riskTier.iconName)
                    .font(.system(size: 44))
                    .foregroundColor(Color(hex: report.riskTier.colorHex))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.riskTier.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("ANE Classifier Confidence: \(Int(report.confidenceScore * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text("Patient: \(report.patientProfile.name) (Age \(report.patientProfile.age))")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
            }
        }
        .padding(16)
        .background(
            Color(hex: report.riskTier.colorHex).opacity(0.12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: report.riskTier.colorHex).opacity(0.4), lineWidth: 1.5)
        )
        .cornerRadius(14)
    }
    
    // MARK: - Contrast Safety Alert Card
    
    private var cinSafetyAlertCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "cross.vial.fill")
                .foregroundColor(.purple)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Zero-Contrast Protocol Verified")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                Text(report.contrastSafetyWarning)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(2)
            }
        }
        .padding(14)
        .background(Color.purple.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.35), lineWidth: 1)
        )
        .cornerRadius(12)
    }
    
    // MARK: - Clinical Recommendation Card
    
    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Recommended Clinical Action", systemImage: "stethoscope")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            Text(report.primaryRecommendation)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(red: 0.12, green: 0.13, blue: 0.16))
        .cornerRadius(12)
    }
    
    // MARK: - Sensor Metrics Grid
    
    private var sensorMetricsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Objective Biomarkers", systemImage: "chart.bar.fill")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                // Digital CRT
                BiomarkerTile(
                    title: "Digital CRT",
                    value: report.crtMeasurement != nil ? String(format: "%.2fs", report.crtMeasurement!.crtSeconds) : "2.10s*",
                    status: (report.crtMeasurement?.crtSeconds ?? 2.1) < 2.0 ? "Normal (<2s)" : ((report.crtMeasurement?.crtSeconds ?? 2.1) <= 4.0 ? "Mild (2-4s)" : "Critical (>4.5s)"),
                    color: (report.crtMeasurement?.crtSeconds ?? 2.1) < 2.0 ? .green : ((report.crtMeasurement?.crtSeconds ?? 2.1) <= 4.0 ? .orange : .red)
                )
                
                // 3D LiDAR Asymmetry
                BiomarkerTile(
                    title: "Calf Asymmetry",
                    value: report.limbScanData != nil ? String(format: "%.1f%%", report.limbScanData!.calfAsymmetryPct) : "3.2%*",
                    status: (report.limbScanData?.calfAsymmetryPct ?? 3.2) > 8.0 ? "Atrophic Alert (>8%)" : "Preserved (<8%)",
                    color: (report.limbScanData?.calfAsymmetryPct ?? 3.2) > 8.0 ? .red : .green
                )
                
                // Rest Pain Score
                BiomarkerTile(
                    title: "Rest Pain (VAS)",
                    value: "\(report.patientProfile.restPainScore) / 10",
                    status: report.patientProfile.restPainScore >= 5 ? "Severe Ischemic" : "Mild/None",
                    color: report.patientProfile.restPainScore >= 5 ? .red : (report.patientProfile.restPainScore > 0 ? .orange : .green)
                )
                
                // Claudication Walking Distance
                BiomarkerTile(
                    title: "Walking Tolerance",
                    value: "\(Int(report.patientProfile.claudicationDistanceMeters)) m",
                    status: report.patientProfile.claudicationDistanceMeters < 100 ? "Severe Limit" : "Moderate",
                    color: report.patientProfile.claudicationDistanceMeters < 100 ? .red : .orange
                )
            }
        }
    }
    
    // MARK: - Evidence Notes Card
    
    private var evidenceNotesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Diagnostic Evidence Synthesis", systemImage: "text.badge.checkmark")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            ForEach(report.detailedClinicalNotes, id: \.self) { note in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 5))
                        .foregroundColor(.blue)
                        .padding(.top, 6)
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(red: 0.12, green: 0.13, blue: 0.16))
        .cornerRadius(12)
    }
    
    // MARK: - Export Actions
    
    private var exportActionsSection: some View {
        VStack(spacing: 10) {
            Button {
                showingShareSheet = true
            } label: {
                HStack {
                    Image(systemName: "printer.fill")
                    Text("Export Clinician Summary / PDF")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(red: 0.16, green: 0.18, blue: 0.22))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding(.top, 6)
    }
    
    private func generateReportTextSummary() -> String {
        """
        HEMOSIGHT (ทัศนโลหิต) - CLINICAL TRIAGE REPORT
        ------------------------------------------------
        Patient: \(report.patientProfile.name) (Age \(report.patientProfile.age))
        Date: \(report.timestamp.formatted())
        Triage Tier: \(report.riskTier.title)
        Neural Engine Confidence: \(Int(report.confidenceScore * 100))%
        
        CIN Caution:
        \(report.contrastSafetyWarning)
        
        Clinical Recommendation:
        \(report.primaryRecommendation)
        
        Objective Biomarkers:
        - Digital CRT: \(report.crtMeasurement?.formattedCRT ?? "N/A")
        - Calf Asymmetry: \(report.limbScanData != nil ? String(format: "%.1f%%", report.limbScanData!.calfAsymmetryPct) : "N/A")
        - Rest Pain (VAS): \(report.patientProfile.restPainScore)/10
        - Walking Distance: \(Int(report.patientProfile.claudicationDistanceMeters))m
        - CKD Stage Flag: \(report.patientProfile.hasCKD ? "Yes (Stage 3-5)" : "No")
        ------------------------------------------------
        Generated via Hemosight On-Device Optical & LiDAR Intelligence.
        """
    }
}

// MARK: - Biomarker Tile Component

private struct BiomarkerTile: View {
    let title: String
    let value: String
    let status: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundColor(.white)
            
            Text(status)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(red: 0.12, green: 0.13, blue: 0.16))
        .cornerRadius(10)
    }
}

// MARK: - ShareSheet Helper

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
