import SwiftUI
import Combine

/// Minimalist, intuitive Clinical Questionnaire.
/// Built strictly following `swiftui-pro` standards:
/// - Uses `foregroundStyle()`, `clipShape(.rect(cornerRadius:))`
/// - Applies `.scrollIndicators(.hidden)` and `LabeledContent`
/// - Enforces 44x44 minimum touch targets and semantic toolbars
/// - Leverages `#Preview`
public struct QuestionnaireView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    @State private var patientName: String = ""
    @State private var age: Int = 68
    @State private var hasCKD: Bool = true
    @State private var hasDiabetes: Bool = true
    @State private var isSmoker: Bool = false
    @State private var restPainScore: Double = 3.0
    @State private var claudicationDistance: Double = 180.0
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Quick Presets
                    presetSection
                    
                    // Nocturnal Rest Pain Card
                    restPainCard
                    
                    // Claudication Walking Distance Card
                    claudicationCard
                    
                    // Clinical Conditions
                    clinicalConditionsCard
                    
                    // Save Action
                    saveButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .background(Color.pastelBackground.ignoresSafeArea())
            .navigationTitle("Clinical Questionnaire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
            .onAppear {
                let p = appState.currentPatient
                self.patientName = p.name
                self.age = p.age
                self.hasCKD = p.hasCKD
                self.hasDiabetes = p.hasDiabetes
                self.isSmoker = p.isSmoker
                self.restPainScore = Double(p.restPainScore)
                self.claudicationDistance = p.claudicationDistanceMeters
            }
        }
    }
    
    // MARK: - Subcomponents
    
    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QUICK CLINICAL CASE")
                .font(.footnote)
                .bold()
                .foregroundStyle(.secondary)
            
            HStack(spacing: 10) {
                Button {
                    loadProfile(PatientProfile.elderlyDialysisPatient)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(Color.pastelPeach)
                        Text("Grandma Somchai")
                            .font(.subheadline)
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .background(Color.white.opacity(0.06))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                
                Button {
                    loadProfile(PatientProfile.standardHealthyAdult)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.footnote)
                            .foregroundStyle(Color.pastelMint)
                        Text("Healthy Adult")
                            .font(.subheadline)
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .background(Color.white.opacity(0.06))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
            }
        }
    }
    
    private var restPainCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            LabeledContent {
                Text("\(Int(restPainScore)) / 10")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(painColor)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nocturnal Rest Pain")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Foot pain at rest / night")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            
            Slider(value: $restPainScore, in: 0...10, step: 1.0)
                .tint(painColor)
            
            Text(painDescription)
                .font(.footnote)
                .foregroundStyle(painColor)
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 20))
    }
    
    private var claudicationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            LabeledContent {
                Text("\(Int(claudicationDistance)) m")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(claudicationColor)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Walking Distance")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Before calf cramping pain")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            
            Slider(value: $claudicationDistance, in: 20...1000, step: 10.0)
                .tint(claudicationColor)
            
            Text(claudicationText)
                .font(.footnote)
                .foregroundStyle(claudicationColor)
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 20))
    }
    
    private var clinicalConditionsCard: some View {
        VStack(spacing: 16) {
            Toggle(isOn: $hasCKD) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Chronic Kidney Disease (CKD)")
                        .font(.body)
                        .foregroundStyle(.white)
                    Text("Stage 3–5 / Dialysis (Avoid contrast dye)")
                        .font(.footnote)
                        .foregroundStyle(Color.pastelLilac)
                }
            }
            .tint(Color.pastelLilac)
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            Toggle("Type 2 Diabetes Mellitus", isOn: $hasDiabetes)
                .font(.body)
                .foregroundStyle(.white)
                .tint(Color.pastelPeriwinkle)
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            Toggle("Current Smoker", isOn: $isSmoker)
                .font(.body)
                .foregroundStyle(.white)
                .tint(.gray)
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 20))
    }
    
    private var saveButton: some View {
        Button {
            saveProfile()
            dismiss()
        } label: {
            Text("Apply Clinical Profile")
                .font(.headline)
                .bold()
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(Color.pastelPeriwinkle)
                .foregroundStyle(.white)
                .clipShape(Capsule())
        }
        .sensoryFeedback(.success, trigger: patientName)
    }
    
    // MARK: - Helpers
    
    private func loadProfile(_ p: PatientProfile) {
        self.patientName = p.name
        self.age = p.age
        self.hasCKD = p.hasCKD
        self.hasDiabetes = p.hasDiabetes
        self.isSmoker = p.isSmoker
        self.restPainScore = Double(p.restPainScore)
        self.claudicationDistance = p.claudicationDistanceMeters
    }
    
    private func saveProfile() {
        appState.currentPatient = PatientProfile(
            name: patientName.isEmpty ? "Patient" : patientName,
            age: age,
            hasCKD: hasCKD,
            hasDiabetes: hasDiabetes,
            restPainScore: Int(restPainScore),
            claudicationDistanceMeters: claudicationDistance,
            isSmoker: isSmoker
        )
    }
    
    private var painColor: Color {
        if restPainScore < 3 { return Color.pastelMint }
        if restPainScore < 6 { return Color.pastelPeach }
        return Color.pastelRose
    }
    
    private var painDescription: String {
        switch Int(restPainScore) {
        case 0: return "No foot pain at rest"
        case 1...3: return "Mild occasional aching"
        case 4...6: return "Disturbing nocturnal pain"
        default: return "Severe ischemic pain (Feet hung off bed)"
        }
    }
    
    private var claudicationColor: Color {
        if claudicationDistance > 400 { return Color.pastelMint }
        if claudicationDistance > 150 { return Color.pastelPeach }
        return Color.pastelRose
    }
    
    private var claudicationText: String {
        if claudicationDistance < 50 { return "Severe impairment (< 50m)" }
        if claudicationDistance < 200 { return "Moderate impairment (50-200m)" }
        if claudicationDistance < 500 { return "Mild impairment (200-500m)" }
        return "Normal walking tolerance (> 500m)"
    }
}

#Preview {
    QuestionnaireView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
