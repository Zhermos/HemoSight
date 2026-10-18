import SwiftUI

// MARK: - Header Progress Indicator (Elderly & Clinically Accessible)

public struct WorkflowStepperHeader: View {
    public let currentStep: ScreeningStep
    
    public init(currentStep: ScreeningStep) {
        self.currentStep = currentStep
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            ForEach(ScreeningStep.allCases) { step in
                VStack(spacing: 4) {
                    Circle()
                        .fill(stepCircleColor(for: step))
                        .frame(width: 28, height: 28)
                        .overlay {
                            Text("\(step.rawValue)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(step.rawValue <= currentStep.rawValue ? Color.white : Color.secondary)
                        }
                    
                    Text(stepName(for: step))
                        .font(.system(size: 10, weight: step == currentStep ? .bold : .regular))
                        .foregroundStyle(step == currentStep ? Color.primary : Color.secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Step \(step.rawValue): \(stepName(for: step)), \(step.rawValue < currentStep.rawValue ? "Completed" : step == currentStep ? "Current step" : "Upcoming")")
                
                if step != ScreeningStep.allCases.last {
                    Rectangle()
                        .fill(step.rawValue < currentStep.rawValue ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 3)
                        .frame(maxWidth: 24)
                        .padding(.bottom, 16)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Workflow progress: Step \(currentStep.rawValue) of \(ScreeningStep.allCases.count)")
    }
    
    private func stepCircleColor(for step: ScreeningStep) -> Color {
        if step.rawValue <= currentStep.rawValue {
            return Color.blue
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    private func stepName(for step: ScreeningStep) -> String {
        switch step {
        case .step1VisualPhoto: return "Foot Photo"
        case .step2FingerPPG: return "Finger Pulse"
        case .step3ToePPG: return "Toe Pulse"
        case .step4Dashboard: return "Results"
        }
    }
}

// MARK: - Previews

#Preview("Step 1 - Foot Photo") {
    WorkflowStepperHeader(currentStep: .step1VisualPhoto)
        .padding()
}

#Preview("Step 2 - Finger Pulse") {
    WorkflowStepperHeader(currentStep: .step2FingerPPG)
        .padding()
}

#Preview("Step 3 - Toe Pulse") {
    WorkflowStepperHeader(currentStep: .step3ToePPG)
        .padding()
}

#Preview("Step 4 - Results") {
    WorkflowStepperHeader(currentStep: .step4Dashboard)
        .padding()
}
