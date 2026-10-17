import SwiftUI
import Charts
import AVFoundation
import Combine

/// Minimalist, high-focus Digital CRT Optical Scanner.
/// Features a clean viewfinder, toe nailbed reticle, live Swift Charts waveform,
/// and intuitive single-button state progression.
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
                        
                        // Centered Minimal Reticle
                        nailbedReticle
                        
                        // Top Floating Guidance Pill
                        VStack {
                            guidancePill
                                .padding(.top, 16)
                            Spacer()
                            liveReflectanceMetric
                                .padding(.bottom, 12)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // MARK: - Waveform & Bottom Panel
                    bottomPerfusionPanel
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        cameraManager.stopScanning()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        cameraManager.setTorch(enabled: !cameraManager.isTorchActive)
                    } label: {
                        Image(systemName: cameraManager.isTorchActive ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(cameraManager.isTorchActive ? .yellow : .white.opacity(0.6))
                    }
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
    
    // MARK: - UI Subcomponents
    
    private var simulatedViewfinderBackground: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.10)
            
            VStack(spacing: 12) {
                Image(systemName: "foot.fill")
                    .font(.system(size: 54))
                    .foregroundColor(.white.opacity(0.12))
                Text("Great Toe Macro Viewfinder")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var nailbedReticle: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    cameraManager.capturePhase == .compressing ? Color.orange :
                    cameraManager.capturePhase == .releasing ? Color.green : Color.white.opacity(0.7),
                    lineWidth: 2.5
                )
                .frame(width: 130, height: 130)
            
            // Subtle center cross
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.white.opacity(0.4))
            
            Text("TOE NAILBED")
                .font(.system(size: 9, weight: .heavy))
                .foregroundColor(.white.opacity(0.7))
                .offset(y: 48)
        }
    }
    
    private var guidancePill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(phaseColor)
                .frame(width: 8, height: 8)
            
            Text(cameraManager.capturePhase.rawValue)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
    
    private var liveReflectanceMetric: some View {
        HStack {
            Text("Reflectance I_R:")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Text(String(format: "%.3f", cameraManager.currentRedIntensity))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.red)
            Spacer()
            
            if cameraManager.isSimulated {
                Text("SIMULATED")
                    .font(.system(size: 9, weight: .heavy))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.yellow.opacity(0.2))
                    .foregroundColor(.yellow)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Bottom Perfusion Panel
    
    private var bottomPerfusionPanel: some View {
        VStack(spacing: 16) {
            // Header with live CRT reading
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Perfusion Waveform")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }
                Spacer()
                
                if let crt = cameraManager.latestMeasurement {
                    HStack(spacing: 6) {
                        Text(crt.formattedCRT)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(crt.crtSeconds < 2.0 ? .green : (crt.crtSeconds <= 4.0 ? .orange : .red))
                        Text(crt.clinicalTier.localizedName)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(crt.crtSeconds < 2.0 ? .green : (crt.crtSeconds <= 4.0 ? .orange : .red))
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Minimal Swift Charts Waveform
            Chart {
                ForEach(Array(cameraManager.waveformHistory.enumerated()), id: \.offset) { idx, val in
                    LineMark(
                        x: .value("Frame", idx),
                        y: .value("I", val)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.red)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    
                    AreaMark(
                        x: .value("Frame", idx),
                        y: .value("I", val)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.red.opacity(0.3), Color.red.opacity(0.0)],
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
            
            // Primary Action Pill
            actionControlArea
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .padding(.top, 16)
        .background(Color(red: 0.07, green: 0.08, blue: 0.10))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
    
    // MARK: - Action Buttons
    
    private var actionControlArea: some View {
        VStack(spacing: 10) {
            if cameraManager.capturePhase == .compressing {
                Button {
                    cameraManager.triggerReleaseBlanching()
                } label: {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                        Text("Release Pressure Now")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .foregroundColor(.black)
                    .clipShape(Capsule())
                }
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
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
            } else {
                HStack(spacing: 12) {
                    Button {
                        cameraManager.startScanning()
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Blanching Scan")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                    
                    // Demo Simulation button
                    Button {
                        cameraManager.startSimulationStream()
                    } label: {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 18))
                            .frame(width: 52, height: 52)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.yellow)
                            .clipShape(Circle())
                    }
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
