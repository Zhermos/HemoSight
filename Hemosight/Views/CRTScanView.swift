import SwiftUI
import Charts
import AVFoundation
import Combine

/// Minimalist, high-focus Digital CRT Optical Scanner.
/// Built strictly following `swiftui-pro` standards:
/// - Uses `foregroundStyle()` and `clipShape(.rect(cornerRadius:))`
/// - Applies `.sensoryFeedback()` for tactile button responses
/// - Enforces 44x44 minimum tap areas and semantic toolbars
/// - Leverages `#Preview`
public struct CRTScanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    @StateObject private var cameraManager = CRTCameraManager()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Viewfinder Screen
                    ZStack {
                        if cameraManager.isSimulated {
                            simulatedViewfinderBackground
                        } else {
                            CameraPreviewRepresentable(session: cameraManager.captureSession)
                                .ignoresSafeArea()
                        }
                        
                        nailbedReticle
                        
                        VStack {
                            guidancePill
                                .padding(.top, 16)
                            Spacer()
                            liveReflectanceMetric
                                .padding(.bottom, 12)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // MARK: - Bottom Perfusion Panel
                    bottomPerfusionPanel
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark.circle.fill") {
                        cameraManager.stopScanning()
                        dismiss()
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(minWidth: 44, minHeight: 44)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(
                        cameraManager.isTorchActive ? "Turn Torch Off" : "Turn Torch On",
                        systemImage: cameraManager.isTorchActive ? "bolt.fill" : "bolt.slash.fill"
                    ) {
                        cameraManager.setTorch(enabled: !cameraManager.isTorchActive)
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(cameraManager.isTorchActive ? .yellow : .white.opacity(0.7))
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
            .onAppear {
                cameraManager.setupCamera()
                cameraManager.startScanning()
            }
            .onDisappear {
                cameraManager.stopScanning()
            }
        }
    }
    
    // MARK: - Subcomponents
    
    private var simulatedViewfinderBackground: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.10)
            
            VStack(spacing: 12) {
                Image(systemName: "foot.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(.white.opacity(0.15))
                Text("Great Toe Macro Viewfinder")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var nailbedReticle: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    cameraManager.capturePhase == .compressing ? Color.orange :
                    cameraManager.capturePhase == .releasing ? Color.green : Color.white.opacity(0.7),
                    lineWidth: 2.5
                )
                .frame(width: 130, height: 130)
            
            Image(systemName: "plus")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.4))
            
            Text("TOE NAILBED")
                .font(.caption2)
                .bold()
                .foregroundStyle(.white.opacity(0.7))
                .offset(y: 48)
        }
    }
    
    private var guidancePill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(phaseColor)
                .frame(width: 8, height: 8)
            
            Text(cameraManager.capturePhase.rawValue)
                .font(.subheadline)
                .bold()
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
    
    private var liveReflectanceMetric: some View {
        HStack {
            Text("Reflectance I_R:")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(String(format: "%.3f", cameraManager.currentRedIntensity))
                .font(.subheadline)
                .bold()
                .monospacedDigit()
                .foregroundStyle(.red)
            Spacer()
            
            if cameraManager.isSimulated {
                Text("SIMULATED")
                    .font(.caption2)
                    .bold()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.2))
                    .foregroundStyle(.yellow)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var bottomPerfusionPanel: some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("PERFUSION WAVEFORM")
                    .font(.footnote)
                    .bold()
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if let crt = cameraManager.latestMeasurement {
                    HStack(spacing: 6) {
                        Text(crt.formattedCRT)
                            .font(.title3)
                            .bold()
                            .foregroundStyle(crt.crtSeconds < 2.0 ? .green : (crt.crtSeconds <= 4.0 ? .orange : .red))
                        Text(crt.clinicalTier.localizedName)
                            .font(.footnote)
                            .bold()
                            .foregroundStyle(crt.crtSeconds < 2.0 ? .green : (crt.crtSeconds <= 4.0 ? .orange : .red))
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Chart {
                ForEach(Array(cameraManager.waveformHistory.enumerated()), id: \.offset) { idx, val in
                    LineMark(
                        x: .value("Frame", idx),
                        y: .value("Intensity", val)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.red)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    
                    AreaMark(
                        x: .value("Frame", idx),
                        y: .value("Intensity", val)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.red.opacity(0.35), Color.red.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                if let m = cameraManager.latestMeasurement {
                    RuleMark(y: .value("90%", m.recoveryThresholdIntensity))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(Color.green)
                }
            }
            .chartYScale(domain: 0.25...0.95)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 100)
            .padding(.horizontal, 12)
            
            actionControlArea
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .padding(.top, 16)
        .background(Color(red: 0.07, green: 0.08, blue: 0.10))
        .clipShape(.rect(cornerRadius: 28))
    }
    
    private var actionControlArea: some View {
        VStack(spacing: 10) {
            if cameraManager.capturePhase == .compressing {
                Button {
                    cameraManager.triggerReleaseBlanching()
                } label: {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                        Text("Release Pressure Now")
                            .font(.headline)
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(Color.green)
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
                }
                .sensoryFeedback(.impact(weight: .heavy), trigger: cameraManager.capturePhase)
            } else if cameraManager.capturePhase == .completed || cameraManager.latestMeasurement != nil {
                Button {
                    if let measurement = cameraManager.latestMeasurement {
                        appState.currentCRT = measurement
                    }
                    cameraManager.stopScanning()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save CRT Measurement")
                            .font(.headline)
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .sensoryFeedback(.success, trigger: cameraManager.latestMeasurement?.id)
            } else {
                HStack(spacing: 12) {
                    Button {
                        cameraManager.startScanning()
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Blanching Scan")
                                .font(.headline)
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                    .sensoryFeedback(.impact(weight: .medium), trigger: cameraManager.isSessionRunning)
                    
                    Button {
                        cameraManager.startSimulationStream()
                    } label: {
                        Image(systemName: "wand.and.stars")
                            .font(.title3)
                            .frame(width: 52, height: 52)
                            .background(Color.white.opacity(0.08))
                            .foregroundStyle(.yellow)
                            .clipShape(Circle())
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
    }
    
    private var phaseColor: Color {
        switch cameraManager.capturePhase {
        case .idle: return .gray
        case .acquiringBaseline: return .blue
        case .compressing: return .orange
        case .releasing: return .green
        case .calculating: return .purple
        case .completed: return .green
        case .failed: return .red
        }
    }
}

// MARK: - Camera Preview Representable

private struct CameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {}
}

private class CameraPreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}

#Preview {
    CRTScanView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
