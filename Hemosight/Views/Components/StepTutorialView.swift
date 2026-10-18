import SwiftUI

// MARK: - Resilient Image Loader Helper

/// Loads demonstration images for tutorial steps with multi-tiered resolution:
/// 1. Named asset in main bundle (e.g. "tutorial_step1", "1")
/// 2. Direct file in main bundle ("1.jpg")
/// 3. Subdirectory file in main bundle ("Hemosight/Resources/Images/1.jpg")
/// 4. Local filesystem fallback for dev/preview environments
/// 5. Graceful SF Symbol fallback if image is missing (guaranteed 0 crashes)
public enum TutorialImageLoader {
    public static func loadStepImage(for step: ScreeningStep) -> UIImage? {
        // Step 1: Finger PPG -> demonstration image 2.jpg
        // Step 2: Toe PPG -> demonstration image 3.jpg
        let imageNumber: Int = (step == .step1FingerPPG) ? 2 : (step == .step2ToePPG ? 3 : 1)
        return loadNamedImage(number: imageNumber)
    }
    
    public static func loadFootPhotoImage() -> UIImage? {
        loadNamedImage(number: 1)
    }
    
    private static func loadNamedImage(number: Int) -> UIImage? {
        // 0. Swift Package Manager: Bundle.module
        #if SWIFT_PACKAGE
        if let image = UIImage(named: "tutorial_step\(number)", in: Bundle.module, with: nil) {
            return image
        }
        if let image = UIImage(named: "\(number)", in: Bundle.module, with: nil) {
            return image
        }
        #endif
        
        // 1. Asset Catalog: "tutorial_step\(number)" or "\(number)"
        if let image = UIImage(named: "tutorial_step\(number)") {
            return image
        }
        if let image = UIImage(named: "\(number)") {
            return image
        }
        
        // 2. Direct bundle resource: "\(number).jpg"
        if let path = Bundle.main.path(forResource: "\(number)", ofType: "jpg"),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        
        // 3. Subdirectory in bundle: "Hemosight/Resources/Images/\(number).jpg"
        if let path = Bundle.main.path(forResource: "\(number)", ofType: "jpg", inDirectory: "Hemosight/Resources/Images"),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        if let path = Bundle.main.path(forResource: "\(number)", ofType: "jpg", inDirectory: "Resources/Images"),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        
        // 4. File system fallback for local testing & preview runs
        let candidatePaths = [
            "Hemosight/Resources/Images/\(number).jpg",
            "Resources/Images/\(number).jpg",
            "\(number).jpg"
        ]
        let fileManager = FileManager.default
        let currentDir = fileManager.currentDirectoryPath
        for relativePath in candidatePaths {
            let fullPath = (currentDir as NSString).appendingPathComponent(relativePath)
            if fileManager.fileExists(atPath: fullPath),
               let image = UIImage(contentsOfFile: fullPath) {
                return image
            }
        }
        
        return nil
    }
    
    public static func fallbackSFSymbol(for step: ScreeningStep) -> String {
        switch step {
        case .step1FingerPPG: return "hand.point.up.fill"
        case .step2ToePPG: return "shoe.fill"
        case .step3Dashboard: return "waveform.path.ecg"
        }
    }
}

// MARK: - StepTutorialView Component

public struct StepTutorialView: View {
    public let step: ScreeningStep
    public let viewModel: ScreeningWorkflowViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var dontShowAgain: Bool = false
    
    public init(step: ScreeningStep, viewModel: ScreeningWorkflowViewModel) {
        self.step = step
        self.viewModel = viewModel
        _dontShowAgain = State(initialValue: viewModel.isTutorialSuppressed(for: step))
    }
    
    private var stepBadgeColor: Color {
        switch step {
        case .step1FingerPPG: return .blue
        case .step2ToePPG: return .orange
        case .step3Dashboard: return .purple
        }
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 1. Instructional Illustration Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                        
                        if let image = TutorialImageLoader.loadStepImage(for: step) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 240)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .padding(12)
                        } else {
                            // Safe fallback visual
                            VStack(spacing: 12) {
                                Image(systemName: TutorialImageLoader.fallbackSFSymbol(for: step))
                                    .font(.system(size: 64, weight: .light))
                                    .foregroundStyle(stepBadgeColor)
                                
                                Text(HemosightStrings.stepTutorialSubtitle(for: step, language: viewModel.language))
                                    .appFont(size: 14, weight: .medium)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(height: 220)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // 2. Step Badge and Title Header
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Text(HemosightStrings.stepperShortName(for: step, language: viewModel.language).uppercased())
                                .appFont(size: 12, weight: .bold)
                                .foregroundStyle(stepBadgeColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(stepBadgeColor.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        
                        Text(HemosightStrings.stepTutorialTitle(for: step, language: viewModel.language))
                            .appFont(size: 24, weight: .bold)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.primary)
                            .padding(.horizontal, 20)
                        
                        Text(HemosightStrings.stepTutorialSubtitle(for: step, language: viewModel.language))
                            .appFont(size: 15, weight: .medium)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                    }
                    
                    // 3. Clinical Instructions Checklist Box
                    let checklistItems = HemosightStrings.stepTutorialChecklist(for: step, language: viewModel.language)
                    if !checklistItems.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 8) {
                                Image(systemName: "checklist")
                                    .foregroundStyle(stepBadgeColor)
                                    .font(.system(size: 18, weight: .semibold))
                                
                                Text(HemosightStrings.stepTutorialChecklistHeader(for: viewModel.language))
                                    .appFont(size: 17, weight: .bold)
                                    .foregroundStyle(Color.primary)
                            }
                            .padding(.bottom, 2)
                            
                            ForEach(Array(checklistItems.enumerated()), id: \.offset) { index, item in
                                HStack(alignment: .top, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(stepBadgeColor.opacity(0.15))
                                            .frame(width: 28, height: 28)
                                        Text("\(index + 1)")
                                            .appFont(size: 13, weight: .bold)
                                            .foregroundStyle(stepBadgeColor)
                                    }
                                    
                                    Text(item)
                                        .appFont(size: 15, weight: .regular)
                                        .foregroundStyle(Color.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .lineSpacing(viewModel.language == .thai ? 3.0 : 2.0)
                                }
                            }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // 4. "Don't show again" Checkbox Row (>= 44pt touch target)
                    Button {
                        dontShowAgain.toggle()
                        viewModel.setTutorialSuppressed(dontShowAgain, for: step)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: dontShowAgain ? "checkmark.square.fill" : "square")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(dontShowAgain ? Color.blue : Color.secondary)
                            
                            Text(HemosightStrings.dontShowAgainForStepCheckbox(for: viewModel.language))
                                .appFont(size: 14, weight: .medium)
                                .foregroundStyle(Color.secondary)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                    .padding(.horizontal, 24)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(HemosightStrings.dontShowAgainForStepCheckbox(for: viewModel.language))
                    .accessibilityValue(
                        dontShowAgain 
                            ? (viewModel.language == .thai ? "เลือกแล้ว" : "Checked") 
                            : (viewModel.language == .thai ? "ยังไม่ได้เลือก" : "Unchecked")
                    )
                    
                    // 5. Big Action Button (> 56pt height)
                    Button {
                        handleStartStep()
                    } label: {
                        HStack(spacing: 8) {
                            Text(HemosightStrings.stepTutorialActionButton(for: step, language: viewModel.language))
                                .appFont(size: 17, weight: .bold)
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.blue.opacity(0.25), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.dismissActiveTutorial()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(HemosightStrings.tutorialCloseButton(for: viewModel.language))
                }
            }
        }
        .onAppear {
            dontShowAgain = viewModel.isTutorialSuppressed(for: step)
        }
    }
    
    private func handleStartStep() {
        viewModel.setTutorialSuppressed(dontShowAgain, for: step)
        viewModel.dismissActiveTutorial()
        dismiss()
    }
}

// MARK: - FootPhotoTutorialSheetView (For Results Dashboard Supplemental Scan)

public struct FootPhotoTutorialSheetView: View {
    public let viewModel: ScreeningWorkflowViewModel
    @Environment(\.dismiss) private var dismiss
    
    public init(viewModel: ScreeningWorkflowViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Illustration Card (1.jpg)
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                        
                        if let image = TutorialImageLoader.loadFootPhotoImage() {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 240)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .padding(12)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 64, weight: .light))
                                    .foregroundStyle(Color.blue)
                                Text(HemosightStrings.footPhotoTutorialSubtitle(for: viewModel.language))
                                    .appFont(size: 14, weight: .medium)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(height: 220)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // Title Header
                    VStack(spacing: 8) {
                        Text(HemosightStrings.footPhotoTutorialTitle(for: viewModel.language))
                            .appFont(size: 24, weight: .bold)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.primary)
                            .padding(.horizontal, 20)
                        
                        Text(HemosightStrings.footPhotoTutorialSubtitle(for: viewModel.language))
                            .appFont(size: 15, weight: .medium)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                    }
                    
                    // Checklist Box
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: "checklist")
                                .foregroundStyle(Color.blue)
                                .font(.system(size: 18, weight: .semibold))
                            
                            Text(HemosightStrings.stepTutorialChecklistHeader(for: viewModel.language))
                                .appFont(size: 17, weight: .bold)
                                .foregroundStyle(Color.primary)
                        }
                        .padding(.bottom, 2)
                        
                        let checklistItems = HemosightStrings.footPhotoTutorialChecklist(for: viewModel.language)
                        ForEach(Array(checklistItems.enumerated()), id: \.offset) { index, item in
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.15))
                                        .frame(width: 28, height: 28)
                                    Text("\(index + 1)")
                                        .appFont(size: 13, weight: .bold)
                                        .foregroundStyle(Color.blue)
                                }
                                
                                Text(item)
                                    .appFont(size: 15, weight: .regular)
                                    .foregroundStyle(Color.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineSpacing(viewModel.language == .thai ? 3.0 : 2.0)
                            }
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // Action Button (> 56pt)
                    Button {
                        dismiss()
                    } label: {
                        Text(HemosightStrings.tutorialCloseButton(for: viewModel.language))
                            .appFont(size: 17, weight: .bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Step 1 Tutorial - Finger PPG Thai") {
    StepTutorialView(
        step: .step1FingerPPG,
        viewModel: ScreeningWorkflowViewModel.preview(step: .step1FingerPPG, language: .thai)
    )
}

#Preview("Step 2 Tutorial - Toe PPG English") {
    StepTutorialView(
        step: .step2ToePPG,
        viewModel: ScreeningWorkflowViewModel.preview(step: .step2ToePPG, language: .english)
    )
}

#Preview("Foot Photo Tutorial Sheet") {
    FootPhotoTutorialSheetView(
        viewModel: ScreeningWorkflowViewModel.preview(step: .step3Dashboard, language: .thai)
    )
}
#endif
