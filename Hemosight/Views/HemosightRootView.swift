import SwiftUI

// MARK: - Main Application Container View

public struct HemosightRootView: View {
    @State private var viewModel = ScreeningWorkflowViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Progress Stepper (Elderly Accessible)
                WorkflowStepperHeader(currentStep: viewModel.currentStep)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Active Step Content
                Group {
                    switch viewModel.currentStep {
                    case .step1VisualPhoto:
                        VisualPhotoScanView(viewModel: viewModel)
                    case .step2FingerPPG:
                        PPGScanView(
                            viewModel: viewModel,
                            site: .finger,
                            instruction: "Place your index fingertip gently over the rear camera lens and flash."
                        )
                    case .step3ToePPG:
                        PPGScanView(
                            viewModel: viewModel,
                            site: .toe,
                            instruction: "Rest your big toe gently over the rear camera lens and flash while seated comfortably."
                        )
                    case .step4Dashboard:
                        ClinicalDashboardView(viewModel: viewModel)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Hemosight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset") {
                        viewModel.restartWorkflow()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Reset screening workflow")
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Hemosight Root - Workflow Container") {
    HemosightRootView()
}
