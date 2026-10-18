import SwiftUI

/// Fullscreen elderly-accessible instructional tutorial sheet presented before each screening stage.
/// Displays high-fidelity visual demonstration images (1.jpg, 2.jpg, 3.jpg), concise checklists,
/// a "Don't show again" toggle, and a direct start button.
public struct StepTutorialView: View {
    public let step: ScreeningStep
    public let viewModel: ScreeningWorkflowViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var dontShowAgain: Bool = false
    
    public init(step: ScreeningStep, viewModel: ScreeningWorkflowViewModel) {
        self.step = step
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Step Indicator & Badging
                    HStack {
                        Label(
                            HemosightStrings.tutorialBadge(for: step, language: viewModel.language),
                            systemImage: "lightbulb.fill"
                        )
                        .appFont(size: 13, weight: .bold)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Capsule())
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Step Title & Instructional Summary
                    VStack(alignment: .leading, spacing: 8) {
                        Text(HemosightStrings.tutorialTitle(for: step, language: viewModel.language))
                            .appFont(size: 24, weight: .bold)
                            .foregroundStyle(.primary)
                            .toneMarkSafePadding()
                        
                        Text(HemosightStrings.tutorialSubtitle(for: step, language: viewModel.language))
                            .appFont(size: 15, weight: .regular)
                            .foregroundStyle(.secondary)
                            .toneMarkSafePadding()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Demonstration Image (1.jpg, 2.jpg, 3.jpg)
                    tutorialImageCard
                        .padding(.horizontal, 20)
                    
                    // Key Instructional Checklist
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(HemosightStrings.tutorialPoints(for: step, language: viewModel.language), id: \.text) { point in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: point.icon)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.blue)
                                    .frame(width: 28, height: 28)
                                
                                Text(point.text)
                                    .appFont(size: 15, weight: .medium)
                                    .foregroundStyle(.primary)
                                    .toneMarkSafePadding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(18)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 20)
                    
                    // "Don't show again" Checkbox
                    Button {
                        dontShowAgain.toggle()
                        viewModel.setTutorialDismissed(dontShowAgain, for: step)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: dontShowAgain ? "checkmark.square.fill" : "square")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(dontShowAgain ? .blue : .secondary)
                            
                            Text(HemosightStrings.dontShowAgain(for: viewModel.language))
                                .appFont(size: 15, weight: .regular)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                    
                    // Primary Action Button (Elderly Accessible Touch Target > 56pt)
                    Button {
                        viewModel.dismissActiveTutorial()
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Text(HemosightStrings.tutorialActionButton(for: step, language: viewModel.language))
                                .appFont(size: 18, weight: .bold)
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Re-open Hint Notice
                    HStack(spacing: 6) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 13))
                        Text(HemosightStrings.helpHintNotice(for: viewModel.language))
                            .appFont(size: 12, weight: .regular)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.dismissActiveTutorial()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Close tutorial")
                }
            }
        }
        .onAppear {
            self.dontShowAgain = viewModel.isTutorialDismissed(for: step)
        }
        .environment(\.appLanguage, viewModel.language)
    }
    
    // MARK: - Resilient Image Loader
    
    @ViewBuilder
    private var tutorialImageCard: some View {
        Group {
            if let image = loadTutorialImage() {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
            } else {
                // High-visibility fallback illustration placeholder
                VStack(spacing: 12) {
                    Image(systemName: fallbackIconName)
                        .font(.system(size: 54, weight: .light))
                        .foregroundStyle(.blue)
                    Text(HemosightStrings.tutorialTitle(for: step, language: viewModel.language))
                        .appFont(size: 15, weight: .medium)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
    
    private var fallbackIconName: String {
        switch step {
        case .step1VisualPhoto: return "camera.viewfinder"
        case .step2FingerPPG: return "hand.point.up.left.fill"
        case .step3ToePPG: return "waveform.path.ecg.rectangle"
        case .step4Dashboard: return "doc.text.image"
        }
    }
    
    private func loadTutorialImage() -> UIImage? {
        let stepNumber = step.rawValue
        
        // 1. Try Assets catalog by name: "tutorial_step1", "tutorial_step2", "tutorial_step3"
        let assetName = "tutorial_step\(stepNumber)"
        #if SWIFT_PACKAGE
        if let img = UIImage(named: assetName, in: Bundle.module, with: nil) {
            return img
        }
        #endif
        if let img = UIImage(named: assetName) {
            return img
        }
        if let img = UIImage(named: "\(stepNumber)") {
            return img
        }
        
        // 2. Try App Bundle resource files
        if let bundlePath = Bundle.main.path(forResource: "\(stepNumber)", ofType: "jpg"),
           let img = UIImage(contentsOfFile: bundlePath) {
            return img
        }
        if let bundlePath = Bundle.main.path(forResource: assetName, ofType: "jpg"),
           let img = UIImage(contentsOfFile: bundlePath) {
            return img
        }
        
        // 3. Try Relative and local development directories
        let localPaths = [
            "Hemosight/Resources/Images/\(stepNumber).jpg",
            "Hemosight/Resources/Images/tutorial_step\(stepNumber).jpg",
            "\(stepNumber).jpg",
            "../\(stepNumber).jpg"
        ]
        
        for path in localPaths {
            if let img = UIImage(contentsOfFile: path) {
                return img
            }
        }
        
        return nil
    }
}

// MARK: - Previews

#Preview("Step 1 Tutorial - Foot Photo (Thai)") {
    StepTutorialView(
        step: .step1VisualPhoto,
        viewModel: ScreeningWorkflowViewModel()
    )
}

#Preview("Step 2 Tutorial - Finger Pulse (Thai)") {
    StepTutorialView(
        step: .step2FingerPPG,
        viewModel: ScreeningWorkflowViewModel()
    )
}

#Preview("Step 3 Tutorial - Big Toe Pulse (Thai)") {
    StepTutorialView(
        step: .step3ToePPG,
        viewModel: ScreeningWorkflowViewModel()
    )
}
