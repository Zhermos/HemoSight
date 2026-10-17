import SwiftUI
import ARKit
import RealityKit

/// Interactive ARKit LiDAR 3D scanning interface for bilateral lower limb morphometry.
/// Visualizes live point-cloud density, cross-sectional circumference readouts,
/// and calf circumference asymmetry percentage.
public struct LiDARScanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    @StateObject private var scanner = LiDARScanner()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - 3D AR Scanner Viewport
                    arViewportArea
                        .frame(maxHeight: 330)
                    
                    // MARK: - Live Morphometry Metrics Comparison
                    morphometryMetricsArea
                    
                    // MARK: - Scan Step & Execution Controls
                    scanControlsArea
                }
            }
            .navigationTitle("ARKit 3D LiDAR Morphometry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        scanner.stopScanning()
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                            .foregroundColor(.cyan)
                        Text("\(scanner.meshVertexCount) pts")
                            .font(.caption2)
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onAppear {
                scanner.startScanning()
            }
            .onDisappear {
                scanner.stopScanning()
            }
        }
    }
    
    // MARK: - AR Viewport
    
    private var arViewportArea: some View {
        ZStack {
            if scanner.isLiDARSupported && !scanner.isSimulated {
                ARViewContainer(session: scanner.arSession)
                    .ignoresSafeArea()
            } else {
                simulatedARMeshBackground
            }
            
            // Anatomical Leg Scanning Crosshair & Guides
            VStack {
                Spacer()
                HStack(spacing: 36) {
                    // Left Limb Target Guide
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(scanner.currentStep == .scanningLeft ? Color.cyan : Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 90, height: 180)
                            .overlay(
                                Image(systemName: "figure.walk")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.2))
                            )
                        Text("LEFT LIMB")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(scanner.currentStep == .scanningLeft ? .cyan : .secondary)
                    }
                    
                    // Right Limb Target Guide
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(scanner.currentStep == .scanningRight ? Color.cyan : Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 90, height: 180)
                            .overlay(
                                Image(systemName: "figure.walk")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.2))
                            )
                        Text("RIGHT LIMB")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(scanner.currentStep == .scanningRight ? .cyan : .secondary)
                    }
                }
                Spacer()
            }
            
            // Step Instruction Banner
            VStack {
                Text(scanner.currentStep.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding(.top, 12)
                
                Spacer()
            }
        }
    }
    
    private var simulatedARMeshBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.10, blue: 0.16), Color(red: 0.04, green: 0.06, blue: 0.10)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Stylized 3D mesh contour grid
            VStack(spacing: 12) {
                Image(systemName: "cube.transparent")
                    .font(.system(size: 60))
                    .foregroundColor(.cyan.opacity(0.3))
                Text("LiDAR Depth Mesh Reconstruction (Simulated)")
                    .font(.caption)
                    .foregroundColor(.cyan.opacity(0.8))
            }
        }
    }
    
    // MARK: - Morphometry Metrics Comparison Grid
    
    private var morphometryMetricsArea: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Bilateral Circumference Cross-Sections", systemImage: "ruler.fill")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack(spacing: 12) {
                // Left Limb Column
                VStack(spacing: 6) {
                    Text("LEFT LIMB")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.cyan)
                    
                    MetricBox(label: "Calf Girth", value: String(format: "%.1f cm", scanner.liveLeftCalfCm))
                    MetricBox(label: "Ankle Girth", value: String(format: "%.1f cm", scanner.liveLeftAnkleCm))
                }
                .frame(maxWidth: .infinity)
                
                // Asymmetry Delta Card
                VStack(spacing: 4) {
                    Text("ASYMMETRY")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.1f%%", scanner.liveCalfAsymmetryPct))
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundColor(scanner.liveCalfAsymmetryPct > 8.0 ? .red : .green)
                    
                    Text(scanner.liveCalfAsymmetryPct > 8.0 ? "Atrophy Alert (>8%)" : "Normal (<8%)")
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(scanner.liveCalfAsymmetryPct > 8.0 ? Color.red.opacity(0.25) : Color.green.opacity(0.2))
                        .foregroundColor(scanner.liveCalfAsymmetryPct > 8.0 ? .red : .green)
                        .cornerRadius(4)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 6)
                .background(Color(red: 0.14, green: 0.16, blue: 0.20))
                .cornerRadius(10)
                
                // Right Limb Column
                VStack(spacing: 6) {
                    Text("RIGHT LIMB")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.cyan)
                    
                    MetricBox(label: "Calf Girth", value: String(format: "%.1f cm", scanner.liveRightCalfCm))
                    MetricBox(label: "Ankle Girth", value: String(format: "%.1f cm", scanner.liveRightAnkleCm))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(14)
        .background(Color(red: 0.10, green: 0.11, blue: 0.14))
    }
    
    // MARK: - Controls Area
    
    private var scanControlsArea: some View {
        VStack(spacing: 10) {
            switch scanner.currentStep {
            case .ready, .scanningLeft:
                Button {
                    scanner.transitionToRightLimb()
                } label: {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Next: Scan Right Lower Limb")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.cyan)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }
                
            case .scanningRight:
                Button {
                    scanner.finalizeMorphometry()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Compute Bilateral Asymmetry")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
            case .calculating:
                ProgressView("Analyzing 3D Point Cloud...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundColor(.white)
                
            case .completed:
                Button {
                    if let data = scanner.latestScanData {
                        appState.currentLimbScan = data
                    }
                    scanner.stopScanning()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Save & Attach Morphometry Data")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.green)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }
            }
            
            // Simulation shortcut button
            if !scanner.isScanning {
                Button("Run Simulated Scan Preview") {
                    scanner.startSimulationMorphometry()
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(red: 0.08, green: 0.09, blue: 0.11))
    }
}

// MARK: - Metric Box Component

private struct MetricBox: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(red: 0.14, green: 0.16, blue: 0.20))
        .cornerRadius(8)
    }
}

// MARK: - ARViewContainer (UIViewRepresentable for ARSCNView / RealityKit ARView)

private struct ARViewContainer: UIViewRepresentable {
    let session: ARSession
    
    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView()
        view.session = session
        view.autoenablesDefaultLighting = true
        view.antialiasingMode = .multisampling4X
        return view
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}
