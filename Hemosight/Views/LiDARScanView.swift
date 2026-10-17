import SwiftUI
import ARKit
import RealityKit
import Combine

/// Minimalist, modern ARKit 3D LiDAR Morphometry scanner.
/// Built strictly following `swiftui-pro` standards:
/// - Uses `foregroundStyle()` and `clipShape(.rect(cornerRadius:))`
/// - Applies `.sensoryFeedback()` for step transitions
/// - Enforces 44x44 minimum tap areas and semantic toolbars
/// - Leverages `#Preview`
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
                    // MARK: - 3D Viewport Screen
                    ZStack {
                        if scanner.isLiDARSupported && !scanner.isSimulated {
                            ARViewContainer(session: scanner.arSession)
                                .ignoresSafeArea()
                        } else {
                            simulatedViewportBackground
                        }
                        
                        legGuidesOverlay
                        
                        VStack {
                            stepGuidancePill
                                .padding(.top, 16)
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // MARK: - Metrics & Action Bottom Panel
                    bottomMetricsPanel
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark.circle.fill") {
                        scanner.stopScanning()
                        dismiss()
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(minWidth: 44, minHeight: 44)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 4) {
                        Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                            .font(.footnote)
                            .foregroundStyle(.cyan)
                        Text("\(scanner.meshVertexCount)")
                            .font(.footnote)
                            .bold()
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .frame(minHeight: 44)
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
                    .foregroundStyle(.cyan.opacity(0.3))
                Text("LiDAR 3D Point Cloud")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var legGuidesOverlay: some View {
        HStack(spacing: 36) {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(scanner.currentStep == .scanningLeft ? Color.cyan : Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: 80, height: 160)
                    .background(scanner.currentStep == .scanningLeft ? Color.cyan.opacity(0.08) : Color.clear)
                    .clipShape(.rect(cornerRadius: 16))
                Text("LEFT")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(scanner.currentStep == .scanningLeft ? .cyan : .secondary)
            }
            
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(scanner.currentStep == .scanningRight ? Color.cyan : Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: 80, height: 160)
                    .background(scanner.currentStep == .scanningRight ? Color.cyan.opacity(0.08) : Color.clear)
                    .clipShape(.rect(cornerRadius: 16))
                Text("RIGHT")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(scanner.currentStep == .scanningRight ? .cyan : .secondary)
            }
        }
    }
    
    private var stepGuidancePill: some View {
        Text(scanner.currentStep.rawValue)
            .font(.footnote)
            .bold()
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }
    
    private var bottomMetricsPanel: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text("LEFT LEG")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.secondary)
                    Text(scanner.liveLeftCalfCm > 0 ? String(format: "%.1f cm", scanner.liveLeftCalfCm) : "--")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.white)
                    Text("Calf Girth")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.04))
                .clipShape(.rect(cornerRadius: 16))
                
                VStack(spacing: 4) {
                    Text("ASYMMETRY")
                        .font(.caption2)
                        .bold()
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f%%", scanner.liveCalfAsymmetryPct))
                        .font(.title2)
                        .bold()
                        .foregroundStyle(scanner.liveCalfAsymmetryPct > 8.0 ? .red : (scanner.liveCalfAsymmetryPct > 0 ? .green : .secondary))
                    Text(scanner.liveCalfAsymmetryPct > 8.0 ? "Atrophy" : "Normal")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(scanner.liveCalfAsymmetryPct > 8.0 ? .red : .green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.06))
                .clipShape(.rect(cornerRadius: 16))
                
                VStack(spacing: 4) {
                    Text("RIGHT LEG")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.secondary)
                    Text(scanner.liveRightCalfCm > 0 ? String(format: "%.1f cm", scanner.liveRightCalfCm) : "--")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.white)
                    Text("Calf Girth")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.04))
                .clipShape(.rect(cornerRadius: 16))
            }
            .padding(.horizontal, 20)
            
            actionControlArea
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .padding(.top, 16)
        .background(Color(red: 0.07, green: 0.08, blue: 0.10))
        .clipShape(.rect(cornerRadius: 28))
    }
    
    private var actionControlArea: some View {
        VStack(spacing: 8) {
            switch scanner.currentStep {
            case .ready, .scanningLeft:
                Button {
                    scanner.transitionToRightLimb()
                } label: {
                    HStack {
                        Text("Next: Scan Right Leg")
                            .font(.headline)
                            .bold()
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(Color.cyan)
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
                }
                .sensoryFeedback(.impact(weight: .light), trigger: scanner.currentStep)
                
            case .scanningRight:
                Button {
                    scanner.finalizeMorphometry()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Compute Asymmetry")
                            .font(.headline)
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: scanner.currentStep)
                
            case .calculating:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                
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
                            .font(.headline)
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(Color.green)
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
                }
                .sensoryFeedback(.success, trigger: scanner.currentStep)
            }
            
            if !scanner.isScanning {
                Button("Run Simulated Scan") {
                    scanner.startSimulationMorphometry()
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(minHeight: 44)
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

#Preview {
    LiDARScanView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
