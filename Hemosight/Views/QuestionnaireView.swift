import SwiftUI
import Combine

/// Minimalist, intuitive Clinical Questionnaire.
/// Evaluates nocturnal rest pain (VAS 0-10), claudication walking limit (meters),
/// and nephrology vulnerability flags with instant preset pills.
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
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Quick Presets
                    presetSection
                    
                    // Nocturnal Rest Pain Card
                    restPainCard
                    
                    // Claudication Walking Distance Card
                    claudicationCard
                    
                    // Clinical History & Risk Toggles
                    clinicalConditionsCard
                    
                    // Save Button
                    saveButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(Color(red: 0.04, green: 0.04, blue: 0.06).ignoresSafeArea())
            .navigationTitle("Clinical Questionnaire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.6))
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
    
    // MARK: - Presets
    
    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QUICK CLINICAL CASE")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
            
            HStack(spacing: 10) {
                Button {
                    loadProfile(PatientProfile.elderlyDialysisPatient)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text("Grandma Somchai (CLTI)")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.06))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
                
                Button {
                    loadProfile(PatientProfile.standardHealthyAdult)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        Text("Healthy Adult")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.06))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
            }
        }
    }
    
    // MARK: - Rest Pain Card
    
    private var restPainCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nocturnal Rest Pain")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Foot pain at rest / night")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Text("\(Int(restPainScore)) / 10")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(painColor)
            }
            
            Slider(value: $restPainScore, in: 0...10, step: 1.0)
                .tint(painColor)
            
            Text(painDescription)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(painColor.opacity(0.9))
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    // MARK: - Claudication Card
    
    private var claudicationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Walking Distance")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Before calf cramping pain")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Text("\(Int(claudicationDistance)) m")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(claudicationColor)
            }
            
            Slider(value: $claudicationDistance, in: 20...1000, step: 10.0)
                .tint(claudicationColor)
            
            Text(claudicationText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(claudicationColor.opacity(0.9))
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    // MARK: - Clinical Conditions Card
    
    private var clinicalConditionsCard: some View {
        VStack(spacing: 16) {
            Toggle(isOn: $hasCKD) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Chronic Kidney Disease (CKD)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    Text("Stage 3–5 / Dialysis (Avoid contrast dye)")
                        .font(.system(size: 11))
                        .foregroundColor(.purple)
                }
            }
            .tint(.purple)
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            Toggle("Type 2 Diabetes Mellitus", isOn: $hasDiabetes)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .tint(.blue)
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            Toggle("Current Smoker", isOn: $isSmoker)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .tint(.gray)
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            saveProfile()
            dismiss()
        } label: {
            Text("Apply Clinical Profile")
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
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
        if restPainScore < 3 { return .green }
        if restPainScore < 6 { return .orange }
        return .red
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
        if claudicationDistance > 400 { return .green }
        if claudicationDistance > 150 { return .orange }
        return .red
    }
    
    private var claudicationText: String {
        if claudicationDistance < 50 { return "Severe impairment (< 50m)" }
        if claudicationDistance < 200 { return "Moderate impairment (50-200m)" }
        if claudicationDistance < 500 { return "Mild impairment (200-500m)" }
        return "Normal walking tolerance (> 500m)"
    }
}
