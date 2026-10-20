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
    
    // Supplemental Foot Inspection Card (Enhanced with rich demonstration visual & camera icon)
    private func supplementalFootScanCard(report: ComprehensivePADReport) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with clear badge
            HStack(spacing: 8) {
                Image(systemName: "camera.viewfinder")
                    .foregroundStyle(.blue)
                    .font(.title3)
                Text(HemosightStrings.supplementalFootScanHeader(for: appLanguage))
                    .appFont(size: appLanguage == .thai ? 16 : 17, weight: .bold)
                
                Spacer()
                
                Text(appLanguage == .thai ? "แนะนำ" : "Recommended")
                    .appFont(size: 11, weight: .bold)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
            }
            .toneMarkSafePadding(.bottom, 2)
            
            if let visual = report.visualResult, let footImage = viewModel.capturedFootImage {
                // State A: Foot Photo Already Analyzed
                HStack(spacing: 14) {
                    Image(uiImage: footImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 84, height: 84)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
                        )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(HemosightStrings.supplementalFootScanCompleted(deltaE: visual.deltaE, language: appLanguage))
                            .appFont(size: 14, weight: .bold)
                            .foregroundStyle(Color.primary)
                        
                        Text(visual.isClinicallyAsymmetric 
                             ? (appLanguage == .thai ? "พบความไม่สมมาตรของสีผิว" : "Color asymmetry detected") 
                             : (appLanguage == .thai ? "สีผิวสมมาตรปกติ" : "Normal skin symmetry"))
                            .appFont(size: 13, weight: .regular)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            viewModel.isShowingSupplementalFootCamera = true
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.triangle.2.circlepath.camera")
                                Text(HemosightStrings.supplementalFootScanRetake(for: appLanguage))
                            }
                            .appFont(size: 13, weight: .semibold)
                            .foregroundStyle(.blue)
                        }
                        .padding(.top, 2)
                    }
                }
            } else {
                // State B: Foot Photo Not Yet Taken (Visual Card with Demo Image & Big Camera Button)
                VStack(spacing: 14) {
                    // Visual Preview Row: Shows feet demonstration thumbnail (1.jpg)
                    HStack(spacing: 14) {
                        ZStack(alignment: .bottomTrailing) {
                            if let demoImage = TutorialImageLoader.loadFootPhotoImage() {
                                Image(uiImage: demoImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 84, height: 84)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            } else {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 84, height: 84)
                                    .overlay(
                                        Image(systemName: "feet")
                                            .font(.system(size: 32))
                                            .foregroundStyle(.blue)
                                    )
                            }
                            
                            // Camera Badge Overlay
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(6)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .offset(x: 4, y: 4)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appLanguage == .thai ? "ถ่ายภาพหลังเท้าทั้งสองข้าง" : "Bilateral Dorsal Feet Photo")
                                .appFont(size: 15, weight: .bold)
                                .foregroundStyle(.primary)
                            
                            Text(HemosightStrings.supplementalFootScanPrompt(for: appLanguage))
                                .appFont(size: 12.5, weight: .regular)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Primary Action Button (> 56pt height with Camera Icon)
                    Button {
                        if !viewModel.isTutorialSuppressed(for: .step3Dashboard) {
                            viewModel.isShowingSupplementalFootTutorial = true
                        } else {
                            viewModel.isShowingSupplementalFootCamera = true
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "camera.circle.fill")
                                .font(.system(size: 24, weight: .bold))
                            
                            Text(HemosightStrings.supplementalFootScanButton(for: appLanguage))
                                .appFont(size: appLanguage == .thai ? 15 : 16, weight: .bold)
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
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.blue.opacity(0.25), radius: 6, x: 0, y: 3)
                    }
                    
                    // Secondary Link: View Instructions / Tutorial
                    Button {
                        viewModel.showSupplementalFootTutorial()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "info.circle")
                            Text(HemosightStrings.supplementalFootScanTutorialLink(for: appLanguage))
                        }
                        .appFont(size: 13, weight: .medium)
                        .foregroundStyle(.blue)
                    }
                    .padding(.top, -2)
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
