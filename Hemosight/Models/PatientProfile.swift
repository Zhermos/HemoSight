import Foundation

/// Patient demographic and clinical questionnaire metrics
/// specifically designed for contrast-free PAD/CLI assessment in high-risk renal populations.
public struct PatientProfile: Identifiable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var age: Int
    
    /// Chronic Kidney Disease flag (true if Stage 3-5, eGFR < 60 mL/min/1.73m² or on hemodialysis)
    public var hasCKD: Bool
    
    /// Type 2 Diabetes Mellitus or diabetic neuropathy flag
    public var hasDiabetes: Bool
    
    /// Patient-reported nocturnal rest pain intensity (0 = No pain, 10 = Agonizing ischemic foot pain)
    public var restPainScore: Int
    
    /// Walking distance in meters before severe calf claudication cramp forces cessation (20m - 1000m+)
    public var claudicationDistanceMeters: Double
    
    /// Current smoking status flag
    public var isSmoker: Bool
    
    public init(
        id: UUID = UUID(),
        name: String = "Anonymous Patient",
        age: Int = 68,
        hasCKD: Bool = true,
        hasDiabetes: Bool = true,
        restPainScore: Int = 3,
        claudicationDistanceMeters: Double = 180.0,
        isSmoker: Bool = false
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.hasCKD = hasCKD
        self.hasDiabetes = hasDiabetes
        self.restPainScore = min(10, max(0, restPainScore))
        self.claudicationDistanceMeters = max(10.0, claudicationDistanceMeters)
        self.isSmoker = isSmoker
    }
    
    // MARK: - Clinical Helpers
    
    /// Whether patient meets high-risk renal contrast-contraindication criteria
    public var isNephropathyRiskPopulation: Bool {
        hasCKD || (hasDiabetes && age >= 65)
    }
    
    /// Severity classification based on walking distance
    public var claudicationSeverity: String {
        if claudicationDistanceMeters < 50.0 {
            return "Severe (< 50m)"
        } else if claudicationDistanceMeters < 200.0 {
            return "Moderate (50-200m)"
        } else if claudicationDistanceMeters < 500.0 {
            return "Mild (200-500m)"
        } else {
            return "Asymptomatic (> 500m)"
        }
    }
    
    // MARK: - Mock Presets
    
    public static var elderlyDialysisPatient: PatientProfile {
        PatientProfile(
            name: "Somchai (Grandma Case Study)",
            age: 74,
            hasCKD: true,
            hasDiabetes: true,
            restPainScore: 7,
            claudicationDistanceMeters: 45.0,
            isSmoker: false
        )
    }
    
    public static var standardHealthyAdult: PatientProfile {
        PatientProfile(
            name: "Healthy Cohort Sample",
            age: 52,
            hasCKD: false,
            hasDiabetes: false,
            restPainScore: 0,
            claudicationDistanceMeters: 800.0,
            isSmoker: false
        )
    }
}
