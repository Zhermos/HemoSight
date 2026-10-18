import SwiftUI

// MARK: - Header Progress Indicator (Elderly & Clinically Accessible)

public struct WorkflowStepperHeader: View {
    public let currentStep: ScreeningStep
    @Environment(\.appLanguage) private var appLanguage
    
    public init(currentStep: ScreeningStep) {
        self.currentStep = currentStep
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            ForEach(ScreeningStep.allCases) { step in
                VStack(spacing: 4) {
                    Circle()
                        .fill(stepCircleColor(for: step))
                        .frame(width: 28, height: 28)
                        .overlay {
                            Text("\(step.rawValue)")
                                .appFont(size: 14, weight: .bold)
                                .foregroundStyle(step.rawValue <= currentStep.rawValue ? Color.white : Color.secondary)
                        }
                    
                    Text(HemosightStrings.stepperShortName(for: step, language: appLanguage))
                        .appFont(size: appLanguage == .thai ? 11 : 10, weight: step == currentStep ? .bold : .regular)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(step == currentStep ? Color.primary : Color.secondary)
                        .toneMarkSafePadding(.horizontal, 2)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    HemosightStrings.stepperProgressAccessibility(
                        step: step,
                        current: currentStep,
                        total: ScreeningStep.allCases.count,
                        language: appLanguage
                    )
                )
                
                if step != ScreeningStep.allCases.last {
                    Rectangle()
                        .fill(step.rawValue < currentStep.rawValue ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 3)
                        .frame(maxWidth: 20)
                        .padding(.bottom, 18)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            appLanguage == .thai
                ? "ความคืบหน้าการตรวจ: ขั้นตอนที่ \(currentStep.rawValue) จาก \(ScreeningStep.allCases.count) ขั้นตอน"
                : "Workflow progress: Step \(currentStep.rawValue) of \(ScreeningStep.allCases.count)"
        )
    }
    
    private func stepCircleColor(for step: ScreeningStep) -> Color {
        if step.rawValue <= currentStep.rawValue {
            return Color.blue
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}

// MARK: - Previews

#Preview("Thai Stepper - Step 1") {
    WorkflowStepperHeader(currentStep: .step1VisualPhoto)
        .environment(\.appLanguage, .thai)
        .padding()
}

#Preview("Thai Stepper - Step 3") {
    WorkflowStepperHeader(currentStep: .step3ToePPG)
        .environment(\.appLanguage, .thai)
        .padding()
}

#Preview("English Stepper - Step 2") {
    WorkflowStepperHeader(currentStep: .step2FingerPPG)
        .environment(\.appLanguage, .english)
        .padding()
}

#Preview("English Stepper - Step 4") {
    WorkflowStepperHeader(currentStep: .step4Dashboard)
        .environment(\.appLanguage, .english)
        .padding()
}
