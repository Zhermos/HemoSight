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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Leading: Compact Language Switcher Pill ("🇹🇭 TH ▾" or "🇺🇸 EN ▾")
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
                        HStack(spacing: 3) {
                            Text(viewModel.language.flagEmoji)
                            Text(viewModel.language.shortLabel)
                                .appFont(size: 12, weight: .bold)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .accessibilityLabel(HemosightStrings.languageToggleAccessibilityLabel(current: viewModel.language))
                }
                
                // Principal: Centered navigation title rendering Sukhumvit Set for Thai subtitle
                ToolbarItem(placement: .principal) {
                    if viewModel.language == .thai {
                        HStack(spacing: 5) {
                            Text("Hemosight")
                                .font(.system(size: 17, weight: .bold))
                            Text("คัดกรอง PAD")
                                .appFont(size: 14, weight: .semibold)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Hemosight คัดกรอง PAD")
                    } else {
                        Text("Hemosight")
                            .font(.system(size: 17, weight: .bold))
                            .accessibilityLabel("Hemosight")
                    }
                }
                
                // Trailing: Help Tutorial Button (?) & Reset Workflow Button
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            viewModel.isShowingTutorial = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(.blue)
                        }
                        .accessibilityLabel(HemosightStrings.helpButtonAccessibilityLabel(for: viewModel.language))
                        
                        Button(HemosightStrings.reset(for: viewModel.language)) {
                            viewModel.restartWorkflow()
                        }
                        .appFont(size: 14, weight: .medium)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(HemosightStrings.resetAccessibilityHint(for: viewModel.language))
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingTutorial) {
            TutorialSheetView(isPresented: $viewModel.isShowingTutorial)
                .environment(\.appLanguage, viewModel.language)
        }
        .onAppear {
            if !viewModel.hideTutorialOnLaunch {
                viewModel.isShowingTutorial = true
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
