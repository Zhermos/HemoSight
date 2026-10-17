import SwiftUI
import Charts
import AVFoundation
import Combine

/// Interactive Camera Viewfinder and real-time physiological perfusion waveform visualizer.
/// Tracks toe nailbed blanching recovery and computes digital Capillary Refill Time (CRT).
public struct CRTScanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    @StateObject private var cameraManager = CRTCameraManager()
    @State private var showingDetails = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Camera Viewfinder / Preview
                    viewfinderArea
                        .frame(maxHeight: 340)
                    
                    // MARK: - Live Perfusion Waveform Chart
                    waveformChartArea
                    
                    // MARK: - Controls & Guidance Bar
                    bottomControlsArea
                }
            }
            .navigationTitle("Digital CRT Optical Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        cameraManager.stopScanning()
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        cameraManager.setTorch(enabled: !cameraManager.isTorchActive)
                    } label: {
                        Image(systemName: cameraManager.isTorchActive ? "bolt.fill" : "bolt.slash.fill")
                            .foregroundColor(cameraManager.isTorchActive ? .yellow : .gray)
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
    
    // MARK: - Viewfinder Area
    
    private var viewfinderArea: some View {
        ZStack {
            // Live Camera Feed or Animated Simulation Preview
            if cameraManager.isSimulated {
                simulatedCameraBackground
            } else {
                CameraPreviewRepresentable(session: cameraManager.captureSession)
                    .ignoresSafeArea()
            }
            
            // ROI Reticle overlay over toe nailbed
            VStack {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            cameraManager.capturePhase == .compressing ? Color.orange :
                            cameraManager.capturePhase == .releasing ? Color.green : Color.white.opacity(0.8),
                            lineWidth: 3
                        )
                        .frame(width: 140, height: 140)
                    
                    // Center crosshair
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("TOE NAILBED")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .offset(y: 52)
                }
                Spacer()
            }
            
            // Phase Guidance Pill Overlay
            VStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(phaseIndicatorColor)
                        .frame(width: 10, height: 10)
                    
                    Text(cameraManager.capturePhase.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.top, 12)
                
                Spacer()
                
                // Live Reflectance Intensity Gauge
                HStack {
                    Text("Reflectance I_R:")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    Text(String(format: "%.3f", cameraManager.currentRedIntensity))
                        .font(.caption)
                        .fontWeight(.heavy)
                        .monospacedDigit()
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    if cameraManager.isSimulated {
                        Text("SIMULATED 60 FPS")
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.3))
                            .foregroundColor(.yellow)
                            .cornerRadius(4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }
    
    private var simulatedCameraBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.12, blue: 0.15), Color(red: 0.08, green: 0.06, blue: 0.10)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(spacing: 8) {
                Image(systemName: "foot.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white.opacity(0.15))
                Text("Great Toe Macro Optical Feed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Waveform Chart Area (Swift Charts)
    
    private var waveformChartArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Microvascular Perfusion Curve", systemImage: "waveform.path.ecg")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let crt = cameraManager.latestMeasurement {
                    Text("CRT: \(crt.formattedCRT)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(crt.crtSeconds < 2.0 ? .green : (crt.crtSeconds <= 4.0 ? .orange : .red))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            Chart {
                ForEach(Array(cameraManager.waveformHistory.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Frame", index),
                        y: .value("Intensity", value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.red)
                    .lineStyle(StrokeStyle(lineWidth: 2.2))
                    
                    AreaMark(
                        x: .value("Frame", index),
                        y: .value("Intensity", value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.red.opacity(0.35), Color.red.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                // Baseline rule
                if let measurement = cameraManager.latestMeasurement {
                    RuleMark(y: .value("90% Threshold", measurement.recoveryThresholdIntensity))
                        .lineStyle(StrokeStyle(lineWidth: 1.0, dash: [4, 4]))
                        .foregroundStyle(Color.green)
                        .annotation(position: .top, alignment: .trailing) {
                            Text("90% Reperfusion")
                                .font(.system(size: 9))
                                .foregroundColor(.green)
                        }
                }
            }
            .chartYScale(domain: 0.2...1.0)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .trailing, values: [0.3, 0.5, 0.7, 0.9]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Color.white.opacity(0.1))
                    AxisValueLabel() {
                        if let d = value.as(Double.self) {
                            Text(String(format: "%.1f", d))
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
        .background(Color(red: 0.10, green: 0.11, blue: 0.14))
    }
    
    // MARK: - Bottom Controls Area
    
    private var bottomControlsArea: some View {
        VStack(spacing: 12) {
            // Action buttons according to phase
            if cameraManager.capturePhase == .compressing {
                Button {
                    cameraManager.triggerReleaseBlanching()
                } label: {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                        Text("RELEASE PRESSURE NOW")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.green)
                    .foregroundColor(.black)
                    .cornerRadius(12)
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
                        Text("Accept & Save CRT Measurement")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            } else {
                HStack(spacing: 12) {
                    Button {
                        cameraManager.startScanning()
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Blanching Scan")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button {
                        cameraManager.startSimulationStream()
                    } label: {
                        Image(systemName: "wand.and.stars")
                            .font(.headline)
                            .frame(width: 48, height: 48)
                            .background(Color(red: 0.20, green: 0.22, blue: 0.28))
                            .foregroundColor(.yellow)
                            .cornerRadius(12)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(red: 0.08, green: 0.09, blue: 0.11))
    }
    
    private var phaseIndicatorColor: Color {
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

// MARK: - CameraPreviewRepresentable (UIViewRepresentable for AVFoundation Preview Layer)

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
