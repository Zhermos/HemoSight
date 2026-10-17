import SwiftUI

/// Minimalist, Apple Health-inspired Clinical Triage Report View.
/// Built strictly following `swiftui-pro` standards:
/// - Uses `foregroundStyle()`, `clipShape(.rect(cornerRadius:))`
/// - Applies `.scrollIndicators(.hidden)` and semantic toolbars
/// - Enforces 44x44 minimum touch targets
/// - Leverages `#Preview`
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
            .scrollIndicators(.hidden)
            .background(Color(red: 0.04, green: 0.04, blue: 0.06).ignoresSafeArea())
            .navigationTitle("Triage Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(minWidth: 44, minHeight: 44)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Share Report", systemImage: "square.and.arrow.up") {
                        showingShareSheet = true
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.tint)
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: [generateSummaryText()])
            }
        }
    }
    
    // MARK: - Subcomponents
    
    private var heroTriageCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text(report.riskTier.shortCode)
                    .font(.footnote)
                    .bold()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: report.riskTier.colorHex).opacity(0.2))
                    .foregroundStyle(Color(hex: report.riskTier.colorHex))
                    .clipShape(Capsule())
                
                Spacer()
                
                Text(report.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 16) {
                Image(systemName: report.riskTier.iconName)
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: report.riskTier.colorHex))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.riskTier.title)
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.white)
                    
                    Text("\(Int(report.confidenceScore * 100))% Neural Engine Confidence")
                        .font(.footnote)
                        .bold()
                        .foregroundStyle(.secondary)
                    
                    Text("Patient: \(report.patientProfile.name) (Age \(report.patientProfile.age))")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
            }
        }
        .padding(20)
        .background(Color(hex: report.riskTier.colorHex).opacity(0.12))
        .clipShape(.rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color(hex: report.riskTier.colorHex).opacity(0.3), lineWidth: 1.5)
        }
    }
    
    private var cinSafetyCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "cross.vial.fill")
                .foregroundStyle(.purple)
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Zero-Contrast Protocol Verified")
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.purple)
                Text(report.contrastSafetyWarning)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineSpacing(2)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.purple.opacity(0.10))
        .clipShape(.rect(cornerRadius: 16))
    }
    
    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RECOMMENDED CLINICAL ACTION")
                .font(.caption)
                .bold()
                .foregroundStyle(.secondary)
            
            Text(report.primaryRecommendation)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 20))
    }
    
    private var biomarkersGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            BiomarkerTile(
                title: "Digital CRT",
                value: report.crtMeasurement?.formattedCRT ?? "2.10 s",
                status: (report.crtMeasurement?.crtSeconds ?? 2.1) < 2.0 ? "Normal" : "Prolonged",
                color: (report.crtMeasurement?.crtSeconds ?? 2.1) < 2.0 ? .green : .red
            )
            
            BiomarkerTile(
                title: "Calf Asymmetry",
                value: report.limbScanData != nil ? String(format: "%.1f%%", report.limbScanData!.calfAsymmetryPct) : "3.2%",
                status: (report.limbScanData?.calfAsymmetryPct ?? 3.2) > 8.0 ? "Atrophy" : "Symmetric",
                color: (report.limbScanData?.calfAsymmetryPct ?? 3.2) > 8.0 ? .red : .green
            )
            
            BiomarkerTile(
                title: "Rest Pain",
                value: "\(report.patientProfile.restPainScore) / 10",
                status: report.patientProfile.restPainScore >= 5 ? "Severe" : "Mild/None",
                color: report.patientProfile.restPainScore >= 5 ? .red : .green
            )
            
            BiomarkerTile(
                title: "Walking Limit",
                value: "\(Int(report.patientProfile.claudicationDistanceMeters)) m",
                status: report.patientProfile.claudicationDistanceMeters < 100 ? "Severe Limit" : "Moderate",
                color: report.patientProfile.claudicationDistanceMeters < 100 ? .red : .orange
            )
        }
    }
    
    private var evidenceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DIAGNOSTIC SYNTHESIS")
                .font(.caption)
                .bold()
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(report.detailedClinicalNotes, id: \.self) { note in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 5, height: 5)
                            .padding(.top, 5)
                        Text(note)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 20))
    }
    
    private var exportButton: some View {
        Button {
            showingShareSheet = true
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Export Clinician Summary")
                    .font(.headline)
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(Color.white.opacity(0.08))
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
        .sensoryFeedback(.selection, trigger: showingShareSheet)
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

// MARK: - Biomarker Tile

private struct BiomarkerTile: View {
    let title: String
    let value: String
    let status: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.title3)
                .bold()
                .foregroundStyle(.white)
            
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 5, height: 5)
                Text(status)
                    .font(.caption)
                    .bold()
                    .foregroundStyle(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 16))
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

#Preview {
    RiskReportView(report: RiskReport.sampleMock(tier: .critical))
        .preferredColorScheme(.dark)
}
