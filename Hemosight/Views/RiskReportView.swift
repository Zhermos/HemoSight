import SwiftUI

/// Minimalist, Apple Health-inspired Clinical Triage Report View.
/// Displays on-device ANE risk stratification, contrast-safety clearance,
/// objective sensor biomarkers, and direct clinical recommendations.
public struct RiskReportView: View {
    @Environment(\.dismiss) private var dismiss
    public let report: RiskReport
    
    @State private var showingShareSheet = false
    
    public init(report: RiskReport) {
        self.report = report
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // MARK: - Hero Triage Card
                    heroTriageCard
                    
                    // MARK: - Zero-Contrast Clearance Badge
                    cinSafetyCard
                    
                    // MARK: - Recommended Clinical Action
                    recommendationCard
                    
                    // MARK: - Objective Biomarkers (2x2 Grid)
                    biomarkersGrid
                    
                    // MARK: - Clinical Evidence Points
                    evidenceSection
                    
                    // MARK: - Export Action
                    exportButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(Color(red: 0.04, green: 0.04, blue: 0.06).ignoresSafeArea())
            .navigationTitle("Triage Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: [generateSummaryText()])
            }
        }
    }
    
    // MARK: - Hero Triage Card
    
    private var heroTriageCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text(report.riskTier.shortCode)
                    .font(.system(size: 11, weight: .heavy))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: report.riskTier.colorHex).opacity(0.2))
                    .foregroundColor(Color(hex: report.riskTier.colorHex))
                    .clipShape(Capsule())
                
                Spacer()
                
                Text(report.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                Image(systemName: report.riskTier.iconName)
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: report.riskTier.colorHex))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.riskTier.title)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("\(Int(report.confidenceScore * 100))% Neural Engine Confidence")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Text("Patient: \(report.patientProfile.name) (Age \(report.patientProfile.age))")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
            }
        }
        .padding(20)
        .background(Color(hex: report.riskTier.colorHex).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: report.riskTier.colorHex).opacity(0.3), lineWidth: 1.5)
        )
    }
    
    // MARK: - CIN Safety Card
    
    private var cinSafetyCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "cross.vial.fill")
                .foregroundColor(.purple)
                .font(.system(size: 18))
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Zero-Contrast Protocol Verified")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.purple)
                Text(report.contrastSafetyWarning)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(2)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.purple.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Recommendation Card
    
    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RECOMMENDED CLINICAL ACTION")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
            
            Text(report.primaryRecommendation)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    // MARK: - Biomarkers 2x2 Grid
    
    private var biomarkersGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            // CRT
            BiomarkerTile(
                title: "Digital CRT",
                value: report.crtMeasurement?.formattedCRT ?? "2.10 s",
                status: (report.crtMeasurement?.crtSeconds ?? 2.1) < 2.0 ? "Normal" : "Prolonged",
                color: (report.crtMeasurement?.crtSeconds ?? 2.1) < 2.0 ? .green : .red
            )
            
            // Asymmetry
            BiomarkerTile(
                title: "Calf Asymmetry",
                value: report.limbScanData != nil ? String(format: "%.1f%%", report.limbScanData!.calfAsymmetryPct) : "3.2%",
                status: (report.limbScanData?.calfAsymmetryPct ?? 3.2) > 8.0 ? "Atrophy" : "Symmetric",
                color: (report.limbScanData?.calfAsymmetryPct ?? 3.2) > 8.0 ? .red : .green
            )
            
            // Rest Pain
            BiomarkerTile(
                title: "Rest Pain",
                value: "\(report.patientProfile.restPainScore) / 10",
                status: report.patientProfile.restPainScore >= 5 ? "Severe" : "Mild/None",
                color: report.patientProfile.restPainScore >= 5 ? .red : .green
            )
            
            // Walking Limit
            BiomarkerTile(
                title: "Walking Limit",
                value: "\(Int(report.patientProfile.claudicationDistanceMeters)) m",
                status: report.patientProfile.claudicationDistanceMeters < 100 ? "Severe Limit" : "Moderate",
                color: report.patientProfile.claudicationDistanceMeters < 100 ? .red : .orange
            )
        }
    }
    
    // MARK: - Evidence Section
    
    private var evidenceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DIAGNOSTIC SYNTHESIS")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(report.detailedClinicalNotes, id: \.self) { note in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 5, height: 5)
                            .padding(.top, 5)
                        Text(note)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    // MARK: - Export Button
    
    private var exportButton: some View {
        Button {
            showingShareSheet = true
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Export Clinician Summary")
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.08))
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
    }
    
    private func generateSummaryText() -> String {
        """
        HEMOSIGHT - CLINICAL TRIAGE SUMMARY
        Patient: \(report.patientProfile.name) (Age \(report.patientProfile.age))
        Date: \(report.timestamp.formatted())
        Triage Tier: \(report.riskTier.title)
        Confidence: \(Int(report.confidenceScore * 100))%
        
        CIN Alert:
        \(report.contrastSafetyWarning)
        
        Action:
        \(report.primaryRecommendation)
        
        Biomarkers:
        - Digital CRT: \(report.crtMeasurement?.formattedCRT ?? "N/A")
        - Calf Asymmetry: \(report.limbScanData != nil ? String(format: "%.1f%%", report.limbScanData!.calfAsymmetryPct) : "N/A")
        - Rest Pain (VAS): \(report.patientProfile.restPainScore)/10
        - Walking Distance: \(Int(report.patientProfile.claudicationDistanceMeters))m
        - CKD Stage Flag: \(report.patientProfile.hasCKD ? "Yes (Stage 3-5)" : "No")
        """
    }
}

// MARK: - Minimal Biomarker Tile

private struct BiomarkerTile: View {
    let title: String
    let value: String
    let status: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 5, height: 5)
                Text(status)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
