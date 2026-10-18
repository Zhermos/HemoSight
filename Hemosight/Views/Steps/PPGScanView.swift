import SwiftUI
import Charts

// MARK: - Step 2 & 3: Dual-Site PPG Scan View (Finger & Toe)

public struct PPGScanView: View {
    @Bindable public var viewModel: ScreeningWorkflowViewModel
    public let site: PPGSite
    public let instruction: String
    @Environment(\.appLanguage) private var appLanguage
    
    public init(
        viewModel: ScreeningWorkflowViewModel,
        site: PPGSite,
        instruction: String
    ) {
        self.viewModel = viewModel
        self.site = site
        self.instruction = instruction
    }
    
    public var body: some View {
        VStack(spacing: 18) {
            // Guidance Banner
            guidanceBanner
            
            // Real-Time Contact Quality Pill
            contactQualityPill
            
            // Real-Time Pulsatile Swift Chart
            liveWaveformChart
            
            // Countdown Timer Display
            countdownTimerSection
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .appFont(size: 14, weight: .semibold)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Start / Stop Controls (> 56pt height for accessibility)
            scanActionButtons
        }
    }
    
    // MARK: - Subviews
    
    private var guidanceBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: site == .finger ? "hand.point.up.fill" : "figure.walk")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text(HemosightStrings.ppgSiteTitle(for: site, language: appLanguage))
                    .appFont(size: appLanguage == .thai ? 17 : 18, weight: .bold)
            }
            .toneMarkSafePadding(.bottom, 1)
            
            Text(HemosightStrings.ppgInstruction(for: site, language: appLanguage))
                .appFont(size: appLanguage == .thai ? 14 : 15, weight: .regular)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
    }
    
    private var contactQualityPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(contactColor)
                .frame(width: 12, height: 12)
            Text(viewModel.currentContactState.localizedMessage(for: appLanguage))
                .appFont(size: appLanguage == .thai ? 13 : 14, weight: .semibold)
                .foregroundStyle(contactColor)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.currentContactState.localizedMessage(for: appLanguage))
    }
    
    private var contactColor: Color {
        viewModel.currentContactState == .optimal ? Color.green : Color.orange
    }
    
    private var liveWaveformChart: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(HemosightStrings.livePPGChartTitle(for: appLanguage))
                .appFont(size: appLanguage == .thai ? 11 : 12, weight: .bold)
                .foregroundStyle(.secondary)
            
            Chart(viewModel.liveWaveformPoints) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Intensity", point.rawGreen)
                )
                .foregroundStyle(Color.red)
                .interpolationMethod(.linear)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 140)
            .padding(8)
            .background(Color.black.opacity(0.85))
            .clipShape(.rect(cornerRadius: 12))
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(HemosightStrings.livePPGChartTitle(for: appLanguage))
    }
    
    private var countdownTimerSection: some View {
        VStack(spacing: 4) {
            Text("\(viewModel.scanSecondsRemaining)")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundStyle(viewModel.isRecordingPPG ? Color.blue : Color.secondary)
            Text(HemosightStrings.secondsRemainingLabel(for: appLanguage))
                .appFont(size: appLanguage == .thai ? 12 : 11, weight: .semibold)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.scanSecondsRemaining) \(HemosightStrings.secondsRemainingLabel(for: appLanguage))")
    }
    
    @ViewBuilder
    private var scanActionButtons: some View {
        if !viewModel.isRecordingPPG {
            Button {
                Task {
                    await viewModel.startCurrentPPGScan()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "record.circle")
                        .font(.title3)
                    Text(HemosightStrings.startScanButton(site: site, language: appLanguage))
                        .appFont(size: appLanguage == .thai ? 17 : 18, weight: .bold)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: 14))
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            .accessibilityLabel(HemosightStrings.startScanButton(site: site, language: appLanguage))
        } else {
            Button(role: .destructive) {
                viewModel.stopPPGScanEarly()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                    Text(HemosightStrings.cancelScanButton(for: appLanguage))
                        .appFont(size: appLanguage == .thai ? 17 : 18, weight: .bold)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)
                .background(Color.red.opacity(0.15))
                .foregroundStyle(.red)
                .clipShape(.rect(cornerRadius: 14))
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            .accessibilityLabel(HemosightStrings.cancelScanButton(for: appLanguage))
        }
    }
}

// MARK: - Previews

#Preview("Thai Step 2 - Finger PPG Idle") {
    PPGScanView(
        viewModel: .preview(step: .step2FingerPPG, language: .thai),
        site: .finger,
        instruction: "Place your index fingertip gently over the rear camera lens and flash."
    )
    .environment(\.appLanguage, .thai)
}

#Preview("Thai Step 2 - Finger PPG Recording") {
    PPGScanView(
        viewModel: .preview(step: .step2FingerPPG, isRecordingPPG: true, contactState: .optimal, language: .thai),
        site: .finger,
        instruction: "Place your index fingertip gently over the rear camera lens and flash."
    )
    .environment(\.appLanguage, .thai)
}

#Preview("English Step 3 - Toe PPG Idle") {
    PPGScanView(
        viewModel: .preview(step: .step3ToePPG, language: .english),
        site: .toe,
        instruction: "Rest your big toe gently over the rear camera lens and flash while seated comfortably."
    )
    .environment(\.appLanguage, .english)
}
