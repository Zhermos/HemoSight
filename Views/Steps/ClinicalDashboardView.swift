import SwiftUI

// MARK: - Step 4: Clinical Results Dashboard & PDF Share

public struct ClinicalDashboardView: View {
    @Bindable public var viewModel: ScreeningWorkflowViewModel
    @State private var activeShareSheetItem: ShareablePDFItem?
    
    public init(viewModel: ScreeningWorkflowViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let report = viewModel.finalReport {
                    // Overall Risk Badge Card
                    riskBadgeCard(report: report)
                    
                    // Key Findings Summary
                    metricsSummaryCard(report: report)
                    
                    // Clinical Recommendations
                    recommendationsCard(report: report)
                    
                    // Share PDF Report Button (> 56pt height for accessibility)
                    sharePDFButton
                } else {
                    synthesizingPlaceholder
                }
            }
            .padding(.vertical)
        }
        .sheet(item: $activeShareSheetItem) { item in
            PDFShareSheet(activityItems: [item.data])
        }
    }
    
    // MARK: - Subviews
    
    private func riskBadgeCard(report: ComprehensivePADReport) -> some View {
        VStack(spacing: 12) {
            Text(report.overallRiskLevel.rawValue.uppercased())
                .font(.title2.weight(.black))
                .foregroundStyle(report.overallRiskLevel.displayColor)
            
            Text("Vascular Risk Score: \(Int(report.compositeRiskScore)) / 100")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text(report.overallRiskLevel.clinicalSummary)
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(report.overallRiskLevel.displayColor.opacity(0.12))
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(report.overallRiskLevel.displayColor.opacity(0.4), lineWidth: 2)
        )
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Overall Risk: \(report.overallRiskLevel.rawValue), Risk Score: \(Int(report.compositeRiskScore)) out of 100")
    }
    
    private func metricsSummaryCard(report: ComprehensivePADReport) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("VASCULAR SCREENING METRICS")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            
            MetricRow(
                label: "Bilateral Skin Color Disparity (ΔE)",
                value: String(format: "%.2f", report.visualResult.deltaE),
                status: report.visualResult.deltaE > 4.5 ? "Disparity Flagged" : "Normal",
                isWarning: report.visualResult.deltaE > 4.5
            )
            
            MetricRow(
                label: "Toe Systolic Rise Time (SRT)",
                value: "\(Int(report.hemodynamicResult.toeMorphometry.meanSystolicRiseTimeMs)) ms",
                status: report.hemodynamicResult.toeMorphometry.meanSystolicRiseTimeMs > 180 ? "Prolonged / Damped" : "Crisp Upstroke",
                isWarning: report.hemodynamicResult.toeMorphometry.meanSystolicRiseTimeMs > 180
            )
            
            MetricRow(
                label: "Toe-to-Finger Amplitude Ratio",
                value: String(format: "%.2f", report.hemodynamicResult.amplitudeRatio),
                status: report.hemodynamicResult.amplitudeRatio < 0.35 ? "Diminished" : "Robust Perfusion",
                isWarning: report.hemodynamicResult.amplitudeRatio < 0.35
            )
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
        .padding(.horizontal)
    }
    
    private func recommendationsCard(report: ComprehensivePADReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Next Steps & Recommendations", systemImage: "cross.case.fill")
                .font(.headline)
                .foregroundStyle(.blue)
            
            ForEach(report.recommendations, id: \.self) { rec in
                HStack(alignment: .top, spacing: 8) {
                    Text("•").bold()
                    Text(rec).font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
        .padding(.horizontal)
    }
    
    private var sharePDFButton: some View {
        Button {
            if let pdfData = viewModel.generatedPDFData {
                activeShareSheetItem = ShareablePDFItem(data: pdfData)
            }
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up.fill")
                Text("Share Clinical PDF to Doctor")
                    .font(.title3.weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 14))
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .accessibilityLabel("Share Clinical PDF to Doctor")
        .disabled(viewModel.generatedPDFData == nil)
    }
    
    private var synthesizingPlaceholder: some View {
        ProgressView("Synthesizing clinical findings...")
            .padding(40)
            .accessibilityLabel("Synthesizing clinical findings")
    }
}

// MARK: - Previews

#Preview("Step 4 - Low Risk Assessment") {
    ClinicalDashboardView(
        viewModel: .preview(
            step: .step4Dashboard,
            report: .fixture(
                overallRiskLevel: .low,
                compositeRiskScore: 12.0,
                recommendations: [
                    "Normal bilateral perfusion findings.",
                    "Continue routine annual vascular monitoring.",
                    "Maintain healthy diet and regular physical activity."
                ]
            )
        )
    )
}

#Preview("Step 4 - High Risk Assessment") {
    ClinicalDashboardView(
        viewModel: .preview(
            step: .step4Dashboard,
            report: .fixture(
                visualResult: .fixture(deltaE: 6.2, lightnessDisparity: 9.4),
                hemodynamicResult: .fixture(
                    toeMorphometry: .fixture(site: .toe, meanSystolicRiseTimeMs: 220.0, meanPulseAmplitude: 0.3),
                    amplitudeRatio: 0.22,
                    srtDelayMs: 110.0,
                    isToeDicroticNotchLost: true
                ),
                overallRiskLevel: .high,
                compositeRiskScore: 78.0,
                recommendations: [
                    "High probability of hemodynamically significant arterial occlusive disease.",
                    "Urgent referral for Ankle-Brachial Index (ABI) and Arterial Duplex Ultrasound.",
                    "Vascular specialist consultation recommended within 7 days."
                ]
            )
        )
    )
}

#Preview("Step 4 - Synthesizing Loading State") {
    ClinicalDashboardView(
        viewModel: .preview(step: .step4Dashboard, report: nil)
    )
}
