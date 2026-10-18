import SwiftUI

// MARK: - Step 4: Clinical Results Dashboard & PDF Share

public struct ClinicalDashboardView: View {
    @Bindable public var viewModel: ScreeningWorkflowViewModel
    @State private var activeShareSheetItem: ShareablePDFItem?
    @Environment(\.appLanguage) private var appLanguage
    
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
        VStack(spacing: 10) {
            Text(report.overallRiskLevel.localizedTitle(for: appLanguage).uppercased())
                .appFont(size: appLanguage == .thai ? 20 : 22, weight: .black)
                .foregroundStyle(report.overallRiskLevel.displayColor)
                .multilineTextAlignment(.center)
                .toneMarkSafePadding(.bottom, 2)
            
            Text(HemosightStrings.riskScoreTitle(score: Int(report.compositeRiskScore), language: appLanguage))
                .appFont(size: appLanguage == .thai ? 15 : 17, weight: .bold)
                .foregroundStyle(.secondary)
            
            Text(report.overallRiskLevel.localizedSummary(for: appLanguage))
                .appFont(size: appLanguage == .thai ? 14 : 15, weight: .regular)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.horizontal)
                .toneMarkSafePadding(.vertical, 2)
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
        .accessibilityLabel("\(report.overallRiskLevel.localizedTitle(for: appLanguage)), \(HemosightStrings.riskScoreTitle(score: Int(report.compositeRiskScore), language: appLanguage))")
    }
    
    private func metricsSummaryCard(report: ComprehensivePADReport) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(HemosightStrings.metricsSectionTitle(for: appLanguage))
                .appFont(size: appLanguage == .thai ? 12 : 11, weight: .bold)
                .foregroundStyle(.secondary)
                .toneMarkSafePadding(.bottom, 1)
            
            MetricRow(
                label: HemosightStrings.metricColorDisparityLabel(for: appLanguage),
                value: String(format: "%.2f", report.visualResult.deltaE),
                status: HemosightStrings.metricColorDisparityStatus(isWarning: report.visualResult.deltaE > 4.5, language: appLanguage),
                isWarning: report.visualResult.deltaE > 4.5
            )
            
            MetricRow(
                label: HemosightStrings.metricSRTLabel(for: appLanguage),
                value: "\(Int(report.hemodynamicResult.toeMorphometry.meanSystolicRiseTimeMs)) ms",
                status: HemosightStrings.metricSRTStatus(isWarning: report.hemodynamicResult.toeMorphometry.meanSystolicRiseTimeMs > 180, language: appLanguage),
                isWarning: report.hemodynamicResult.toeMorphometry.meanSystolicRiseTimeMs > 180
            )
            
            MetricRow(
                label: HemosightStrings.metricAmplitudeRatioLabel(for: appLanguage),
                value: String(format: "%.2f", report.hemodynamicResult.amplitudeRatio),
                status: HemosightStrings.metricAmplitudeRatioStatus(isWarning: report.hemodynamicResult.amplitudeRatio < 0.35, language: appLanguage),
                isWarning: report.hemodynamicResult.amplitudeRatio < 0.35
            )
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
        .padding(.horizontal)
    }
    
    private func recommendationsCard(report: ComprehensivePADReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text(HemosightStrings.recommendationsHeader(for: appLanguage))
                    .appFont(size: appLanguage == .thai ? 16 : 17, weight: .bold)
            } icon: {
                Image(systemName: "cross.case.fill")
                    .foregroundStyle(.blue)
            }
            .toneMarkSafePadding(.bottom, 2)
            
            ForEach(report.recommendations, id: \.self) { rec in
                let localized = HemosightStrings.localizeRecommendation(rec, language: appLanguage)
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .appFont(size: 15, weight: .bold)
                        .foregroundStyle(.blue)
                    Text(localized)
                        .appFont(size: appLanguage == .thai ? 13.5 : 14, weight: .regular)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
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
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.title3)
                Text(HemosightStrings.sharePDFButton(for: appLanguage))
                    .appFont(size: appLanguage == .thai ? 16 : 17, weight: .bold)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 14))
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .accessibilityLabel(HemosightStrings.sharePDFButton(for: appLanguage))
        .disabled(viewModel.generatedPDFData == nil)
    }
    
    private var synthesizingPlaceholder: some View {
        ProgressView {
            Text(HemosightStrings.synthesizingReport(for: appLanguage))
                .appFont(size: 14, weight: .medium)
                .padding(.top, 4)
        }
        .padding(40)
        .accessibilityLabel(HemosightStrings.synthesizingReport(for: appLanguage))
    }
}

// MARK: - Previews

#Preview("Thai Step 4 - Low Risk Assessment") {
    ClinicalDashboardView(
        viewModel: .preview(
            step: .step4Dashboard,
            report: .fixture(
                overallRiskLevel: .low,
                compositeRiskScore: 12.0,
                recommendations: [
                    "Normal bilateral perfusion findings. Continue routine cardiovascular wellness and foot skin hygiene.",
                    "Continue routine annual vascular monitoring.",
                    "Maintain healthy diet and regular physical activity."
                ]
            ),
            language: .thai
        )
    )
    .environment(\.appLanguage, .thai)
}

#Preview("Thai Step 4 - High Risk Assessment") {
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
                    "URGENT: Schedule in-person clinical evaluation for formal Ankle-Brachial Index (ABI) and Arterial Duplex Ultrasound.",
                    "Severe pulse upstroke delay detected at toe (SRT > 220 ms), characteristic of proximal arterial stenosis.",
                    "Marked attenuation of distal microcirculatory pulse volume (Toe-to-Finger Ratio < 0.20)."
                ]
            ),
            language: .thai
        )
    )
    .environment(\.appLanguage, .thai)
}

#Preview("English Step 4 - Low Risk Assessment") {
    ClinicalDashboardView(
        viewModel: .preview(
            step: .step4Dashboard,
            report: .fixture(
                overallRiskLevel: .low,
                compositeRiskScore: 12.0
            ),
            language: .english
        )
    )
    .environment(\.appLanguage, .english)
}
