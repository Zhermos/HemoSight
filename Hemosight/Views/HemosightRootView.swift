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
                            instruction: HemosightStrings.ppgInstruction(for: .finger, language: viewModel.language)
                        )
                    case .step3ToePPG:
                        PPGScanView(
                            viewModel: viewModel,
                            site: .toe,
                            instruction: HemosightStrings.ppgInstruction(for: .toe, language: viewModel.language)
                        )
                    case .step4Dashboard:
                        ClinicalDashboardView(viewModel: viewModel)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(HemosightStrings.appTitle(for: viewModel.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // EN / TH Language Toggle Switch (Menu with flags)
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        ForEach(AppLanguage.allCases) { lang in
                            Button {
                                viewModel.language = lang
                            } label: {
                                HStack {
                                    Text("\(lang.flagEmoji) \(lang.displayName)")
                                    if viewModel.language == lang {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.language.toggleButtonLabel)
                                .appFont(size: 12, weight: .bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.12))
                                .foregroundStyle(Color.blue)
                                .clipShape(Capsule())
                        }
                    }
                    .accessibilityLabel(HemosightStrings.languageToggleAccessibilityLabel(current: viewModel.language))
                }
                
                // Reset Workflow Button
                ToolbarItem(placement: .topBarTrailing) {
                    Button(HemosightStrings.reset(for: viewModel.language)) {
                        viewModel.restartWorkflow()
                    }
                    .appFont(size: 14, weight: .medium)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(HemosightStrings.resetAccessibilityHint(for: viewModel.language))
                }
            }
        }
        .environment(\.appLanguage, viewModel.language)
    }
}

// MARK: - Previews

#Preview("Hemosight Root - Thai Language") {
    HemosightRootView()
        .environment(\.appLanguage, .thai)
}

#Preview("Hemosight Root - English Language") {
    HemosightRootView()
        .environment(\.appLanguage, .english)
}
