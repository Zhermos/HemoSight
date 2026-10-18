import SwiftUI
import Charts

// MARK: - Step 2 & 3: Dual-Site PPG Scan View (Finger & Toe)

public struct PPGScanView: View {
    @Bindable public var viewModel: ScreeningWorkflowViewModel
    public let site: PPGSite
    public let instruction: String
    
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
            
            Spacer()
            
            // Start / Stop Controls (> 56pt height for accessibility)
            scanActionButtons
        }
    }
    
    // MARK: - Subviews
    
    private var guidanceBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: site == .finger ? "hand.point.up.fill" : "figure.walk")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text(site.rawValue)
                    .font(.title3.weight(.bold))
            }
            Text(instruction)
                .font(.body)
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
            Text(viewModel.currentContactState.rawValue)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(contactColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sensor Contact: \(viewModel.currentContactState.rawValue)")
    }
    
    private var contactColor: Color {
        viewModel.currentContactState == .optimal ? Color.green : Color.orange
    }
    
    private var liveWaveformChart: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("LIVE PHOTOPLETHYSMOGRAM (PPG)")
                .font(.caption.weight(.bold))
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
        .accessibilityLabel("Live Photoplethysmogram signal display")
    }
    
    private var countdownTimerSection: some View {
        VStack(spacing: 4) {
            Text("\(viewModel.scanSecondsRemaining)")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundStyle(viewModel.isRecordingPPG ? Color.blue : Color.secondary)
            Text("SECONDS REMAINING")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.scanSecondsRemaining) seconds remaining")
    }
    
    @ViewBuilder
    private var scanActionButtons: some View {
        if !viewModel.isRecordingPPG {
            Button {
                Task {
                    await viewModel.startCurrentPPGScan()
                }
            } label: {
                HStack {
                    Image(systemName: "record.circle")
                    Text("Start 30s \(site == .finger ? "Finger" : "Toe") Scan")
                        .font(.title3.weight(.bold))
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: 14))
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            .accessibilityLabel("Start 30 second \(site == .finger ? "Finger" : "Toe") Scan")
        } else {
            Button(role: .destructive) {
                viewModel.stopPPGScanEarly()
            } label: {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("Cancel Scan")
                        .font(.title3.weight(.bold))
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)
                .background(Color.red.opacity(0.15))
                .foregroundStyle(.red)
                .clipShape(.rect(cornerRadius: 14))
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            .accessibilityLabel("Cancel current scan")
        }
    }
}

// MARK: - Previews

#Preview("Step 2 - Finger PPG Idle") {
    PPGScanView(
        viewModel: .preview(step: .step2FingerPPG),
        site: .finger,
        instruction: "Place your index fingertip gently over the rear camera lens and flash."
    )
}

#Preview("Step 2 - Finger PPG Recording") {
    PPGScanView(
        viewModel: .preview(step: .step2FingerPPG, isRecordingPPG: true, contactState: .optimal),
        site: .finger,
        instruction: "Place your index fingertip gently over the rear camera lens and flash."
    )
}

#Preview("Step 3 - Toe PPG Idle") {
    PPGScanView(
        viewModel: .preview(step: .step3ToePPG),
        site: .toe,
        instruction: "Rest your big toe gently over the rear camera lens and flash while seated comfortably."
    )
}
