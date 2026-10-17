import SwiftUI
import Combine

/// Patient Symptoms & Clinical History Questionnaire
/// Evaluates Fontaine / Rutherford stages (Claudication distance, nocturnal rest pain)
/// and flags contrast-sensitive renal vulnerability (CKD Stage 3–5).
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
            Form {
                // MARK: - Clinical Preset Quick-Loader
                Section("Clinical Case Presets (Hackathon Demo)") {
                    Button {
                        loadProfile(PatientProfile.elderlyDialysisPatient)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Grandma Somchai (High-Risk Dialysis / CLTI)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                Text("Age 74 • CKD Stage 4 • Rest Pain 7/10 • Claudication 45m")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Button {
                        loadProfile(PatientProfile.standardHealthyAdult)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Healthy Cohort Volunteer")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                Text("Age 52 • Normal Kidneys • Pain 0/10 • Walking >800m")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // MARK: - Patient Demographics & Renal Status
                Section("Demographics & Nephrology Risk") {
                    TextField("Patient Identifier", text: $patientName)
                    
                    Stepper("Age: \(age) years", value: $age, in: 30...105)
                    
                    Toggle(isOn: $hasCKD) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Chronic Kidney Disease (Stage 3–5 / Dialysis)")
                                .fontWeight(.medium)
                            Text("Severe CIN risk: Angiography contrast contraindicated")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                    .tint(.purple)
                    
                    Toggle("Type 2 Diabetes Mellitus", isOn: $hasDiabetes)
                        .tint(.blue)
                    
                    Toggle("Active Tobacco Smoking", isOn: $isSmoker)
                        .tint(.gray)
                }
                
                // MARK: - Nocturnal Rest Pain (Fontaine III)
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Nocturnal Foot Rest Pain")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(Int(restPainScore)) / 10")
                                .font(.headline)
                                .fontWeight(.heavy)
                                .foregroundColor(restPainColor)
                        }
                        
                        Slider(value: $restPainScore, in: 0...10, step: 1.0)
                            .tint(restPainColor)
                        
                        Text(restPainDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Microvascular Rest Pain Assessment")
                } footer: {
                    Text("Rest pain that awakens patient or requires hanging feet over the bedside indicates critical limb ischemia.")
                }
                
                // MARK: - Claudication Walking Distance (Fontaine II)
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Pain-Free Walking Distance")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(Int(claudicationDistance)) meters")
                                .font(.headline)
                                .fontWeight(.heavy)
                                .foregroundColor(claudicationColor)
                        }
                        
                        Slider(value: $claudicationDistance, in: 20...1000, step: 10.0)
                            .tint(claudicationColor)
                        
                        HStack {
                            Text("Rutherford Grade:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(claudicationCategory)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(claudicationColor)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Intermittent Claudication Distance")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(red: 0.07, green: 0.08, blue: 0.10).ignoresSafeArea())
            .navigationTitle("Clinical Questionnaire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveProfile()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
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
    
    // MARK: - Logic Helpers
    
    private func loadProfile(_ profile: PatientProfile) {
        self.patientName = profile.name
        self.age = profile.age
        self.hasCKD = profile.hasCKD
        self.hasDiabetes = profile.hasDiabetes
        self.isSmoker = profile.isSmoker
        self.restPainScore = Double(profile.restPainScore)
        self.claudicationDistance = profile.claudicationDistanceMeters
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
    
    private var restPainColor: Color {
        if restPainScore < 3 { return .green }
        if restPainScore < 6 { return .orange }
        return .red
    }
    
    private var restPainDescription: String {
        switch Int(restPainScore) {
        case 0: return "0: No foot pain at rest"
        case 1...3: return "1–3: Mild occasional ache, resolves spontaneously"
        case 4...6: return "4–6: Disturbing pain at night, relieved by dependency"
        case 7...10: return "7–10: Severe agonizing ischemic pain, inability to sleep"
        default: return ""
        }
    }
    
    private var claudicationColor: Color {
        if claudicationDistance > 400 { return .green }
        if claudicationDistance > 150 { return .orange }
        return .red
    }
    
    private var claudicationCategory: String {
        if claudicationDistance < 50 { return "Severe (< 50m) - Fontaine IIb" }
        if claudicationDistance < 200 { return "Moderate (50-200m) - Fontaine IIb" }
        if claudicationDistance < 500 { return "Mild (200-500m) - Fontaine IIa" }
        return "Asymptomatic / Normal (> 500m)"
    }
}
