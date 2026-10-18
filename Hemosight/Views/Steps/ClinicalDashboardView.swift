import SwiftUI
import PhotosUI

// MARK: - Step 3: Clinical Results Dashboard & PDF Share

public struct ClinicalDashboardView: View {
    @Bindable public var viewModel: ScreeningWorkflowViewModel
    @State private var activeShareSheetItem: ShareablePDFItem?
    @State private var selectedPhotoItem: PhotosPickerItem?
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
                    
                    // Supplemental Foot Skin & Visual Inspection Card (Optional)
                    supplementalFootScanCard(report: report)
                    
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
        .sheet(isPresented: $viewModel.isShowingSupplementalFootTutorial) {
            FootPhotoTutorialSheetView(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $viewModel.isShowingSupplementalFootCamera) {
            CameraCaptureView { capturedImage in
                Task {
                    await viewModel.processSupplementalFootPhoto(capturedImage)
                }
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: .init(
            get: { selectedPhotoItem != nil },
            set: { if !$0 { selectedPhotoItem = nil } }
        ), selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem = newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await viewModel.processSupplementalFootPhoto(image)
                }
                selectedPhotoItem = nil
            }
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
            
            if let visual = report.visualResult {
                MetricRow(
                    label: HemosightStrings.metricColorDisparityLabel(for: appLanguage),
                    value: String(format: "%.2f", visual.deltaE),
                    status: HemosightStrings.metricColorDisparityStatus(isWarning: visual.deltaE > 4.5, language: appLanguage),
                    isWarning: visual.deltaE > 4.5
                )
            }
            
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
    
    // Supplemental Foot Inspection Card (Optional for higher fidelity)
    private func supplementalFootScanCard(report: ComprehensivePADReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "camera.viewfinder")
                    .foregroundStyle(.blue)
                    .font(.title3)
                Text(HemosightStrings.supplementalFootScanHeader(for: appLanguage))
                    .appFont(size: appLanguage == .thai ? 16 : 17, weight: .bold)
            }
            .toneMarkSafePadding(.bottom, 2)
            
            if let visual = report.visualResult, let footImage = viewModel.capturedFootImage {
                // Foot Photo Already Analyzed
                HStack(spacing: 14) {
                    Image(uiImage: footImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
                        )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(HemosightStrings.supplementalFootScanCompleted(deltaE: visual.deltaE, language: appLanguage))
                            .appFont(size: 14, weight: .bold)
                            .foregroundStyle(Color.primary)
                        
                        Text(visual.isClinicallyAsymmetric ? (appLanguage == .thai ? "พบความไม่สมมาตรของสีผิว" : "Color asymmetry detected") : (appLanguage == .thai ? "สีผิวสมมาตรปกติ" : "Normal skin symmetry"))
                            .appFont(size: 13, weight: .regular)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            viewModel.isShowingSupplementalFootCamera = true
                        } label: {
                            Text(HemosightStrings.supplementalFootScanRetake(for: appLanguage))
                                .appFont(size: 13, weight: .semibold)
                                .foregroundStyle(.blue)
                        }
                        .padding(.top, 2)
                    }
                }
            } else {
                // Foot Photo Not Yet Performed (Optional Prompt)
                Text(HemosightStrings.supplementalFootScanPrompt(for: appLanguage))
                    .appFont(size: appLanguage == .thai ? 13.5 : 14, weight: .regular)
                    .foregroundStyle(.secondary)
                    .lineSpacing(appLanguage == .thai ? 3.0 : 2.0)
                
                HStack(spacing: 12) {
                    // Primary Action: Camera Capture (> 56pt height)
                    Button {
                        viewModel.isShowingSupplementalFootCamera = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text(HemosightStrings.supplementalFootScanButton(for: appLanguage))
                                .appFont(size: appLanguage == .thai ? 14 : 15, weight: .bold)
                                .multilineTextAlignment(.center)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 56)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                
                // Secondary Link: View Instructions / Tutorial
                Button {
                    viewModel.showSupplementalFootTutorial()
                } label: {
                    HStack(spacing: 4) {
                        Text(HemosightStrings.supplementalFootScanTutorialLink(for: appLanguage))
                            .appFont(size: 13.5, weight: .medium)
                            .foregroundStyle(.blue)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
                }
            }
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

#Preview("Thai Step 3 - Low Risk Assessment (Hemodynamic Only)") {
    ClinicalDashboardView(
        viewModel: .preview(
            step: .step3Dashboard,
            report: .fixture(
                visualResult: nil,
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

#Preview("Thai Step 3 - High Risk Assessment with Foot Photo") {
    ClinicalDashboardView(
        viewModel: .preview(
            step: .step3Dashboard,
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

#Preview("English Step 3 - Low Risk Assessment") {
    ClinicalDashboardView(
        viewModel: .preview(
            step: .step3Dashboard,
            report: .fixture(
                visualResult: nil,
                overallRiskLevel: .low,
                compositeRiskScore: 12.0
            ),
            language: .english
        )
    )
    .environment(\.appLanguage, .english)
}
