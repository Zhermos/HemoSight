import SwiftUI
import ARKit
import RealityKit
import Combine

/// Minimalist, modern ARKit 3D LiDAR Morphometry scanner.
/// Features a streamlined bilateral leg sweep guide, live circumference readouts,
/// and clear asymmetry indicators.
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
                    // MARK: - 3D Viewport Area
                    ZStack {
                        if scanner.isLiDARSupported && !scanner.isSimulated {
                            ARViewContainer(session: scanner.arSession)
                                .ignoresSafeArea()
                        } else {
                            simulatedViewportBackground
                        }
                        
                        // Minimal Leg Guides
                        legGuidesOverlay
                        
                        // Top Guidance Pill
                        VStack {
                            stepGuidancePill
                                .padding(.top, 16)
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // MARK: - Bilateral Comparison & Action Panel
                    bottomMetricsPanel
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        scanner.stopScanning()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                            .font(.system(size: 11))
                            .foregroundColor(.cyan)
                        Text("\(scanner.meshVertexCount)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
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
    
    // MARK: - Subcomponents
    
    private var simulatedViewportBackground: some View {
        ZStack {
            Color(red: 0.06, green: 0.08, blue: 0.12)
            
            VStack(spacing: 12) {
                Image(systemName: "cube.transparent")
                    .font(.system(size: 48))
                    .foregroundColor(.cyan.opacity(0.3))
                Text("LiDAR 3D Point Cloud")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var legGuidesOverlay: some View {
        HStack(spacing: 36) {
            // Left Leg Guide
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(scanner.currentStep == .scanningLeft ? Color.cyan : Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: 80, height: 160)
                    .background(scanner.currentStep == .scanningLeft ? Color.cyan.opacity(0.08) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                Text("LEFT")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(scanner.currentStep == .scanningLeft ? .cyan : .secondary)
            }
            
            // Right Leg Guide
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(scanner.currentStep == .scanningRight ? Color.cyan : Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: 80, height: 160)
                    .background(scanner.currentStep == .scanningRight ? Color.cyan.opacity(0.08) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                Text("RIGHT")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(scanner.currentStep == .scanningRight ? .cyan : .secondary)
            }
        }
    }
    
    private var stepGuidancePill: some View {
        Text(scanner.currentStep.rawValue)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }
    
    // MARK: - Bottom Metrics Panel
    
    private var bottomMetricsPanel: some View {
        VStack(spacing: 16) {
            // Circumference Comparison Row
            HStack(spacing: 12) {
                // Left Leg
                VStack(spacing: 4) {
                    Text("LEFT LEG")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    Text(scanner.liveLeftCalfCm > 0 ? String(format: "%.1f cm", scanner.liveLeftCalfCm) : "--")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Calf Girth")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                // Asymmetry Delta Center Badge
                VStack(spacing: 4) {
                    Text("ASYMMETRY")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", scanner.liveCalfAsymmetryPct))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(scanner.liveCalfAsymmetryPct > 8.0 ? .red : (scanner.liveCalfAsymmetryPct > 0 ? .green : .secondary))
                    Text(scanner.liveCalfAsymmetryPct > 8.0 ? "Atrophy" : "Normal")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(scanner.liveCalfAsymmetryPct > 8.0 ? .red : .green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                // Right Leg
                VStack(spacing: 4) {
                    Text("RIGHT LEG")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    Text(scanner.liveRightCalfCm > 0 ? String(format: "%.1f cm", scanner.liveRightCalfCm) : "--")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Calf Girth")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 20)
            
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
        VStack(spacing: 8) {
            switch scanner.currentStep {
            case .ready, .scanningLeft:
                Button {
                    scanner.transitionToRightLimb()
                } label: {
                    HStack {
                        Text("Next: Scan Right Leg")
                            .font(.system(size: 16, weight: .bold))
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.cyan)
                    .foregroundColor(.black)
                    .clipShape(Capsule())
                }
                
            case .scanningRight:
                Button {
                    scanner.finalizeMorphometry()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Compute Asymmetry")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
                
            case .calculating:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                
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
                        Text("Save Morphometry Data")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .foregroundColor(.black)
                    .clipShape(Capsule())
                }
            }
            
            if !scanner.isScanning {
                Button("Run Simulated Scan") {
                    scanner.startSimulationMorphometry()
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - ARViewContainer

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
