import Foundation

/// Comprehensive multi-modal risk report synthesizing digital CRT perfusion,
/// 3D LiDAR limb morphometry asymmetry, and clinical profile.
public struct RiskReport: Identifiable, Codable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let riskTier: RiskTier
    public let confidenceScore: Double
    
    // Underlying Data Sources
    public let crtMeasurement: CRTMeasurement?
    public let limbScanData: LimbScanData?
    public let patientProfile: PatientProfile
    
    // Clinical Guidance & Actionable Instructions
    public let primaryRecommendation: String
    public let detailedClinicalNotes: [String]
    public let contrastSafetyWarning: String
    
    public enum RiskTier: Int, Codable, Sendable, Comparable {
        case low = 0
        case moderate = 1
        case critical = 2
        
        public static func < (lhs: RiskTier, rhs: RiskTier) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        
        public var title: String {
            switch self {
            case .low:
                return "Low Risk (Grade 0)"
            case .moderate:
                return "Moderate PAD (Grade 1)"
            case .critical:
                return "Critical Ischemia Alert (CLTI)"
            }
        }
        
        public var shortCode: String {
            switch self {
            case .low: return "LOW"
            case .moderate: return "MODERATE"
            case .critical: return "CRITICAL"
            }
        }
        
        public var colorHex: String {
            switch self {
            case .low: return "#34C759"      // Apple System Green
            case .moderate: return "#FF9500" // Apple System Orange
            case .critical: return "#FF3B30" // Apple System Red
            }
        }
        
        public var iconName: String {
            switch self {
            case .low: return "checkmark.shield.fill"
            case .moderate: return "exclamationmark.triangle.fill"
            case .critical: return "cross.case.fill"
            }
        }
    }
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        riskTier: RiskTier,
        confidenceScore: Double,
        crtMeasurement: CRTMeasurement?,
        limbScanData: LimbScanData?,
        patientProfile: PatientProfile,
        primaryRecommendation: String? = nil,
        detailedClinicalNotes: [String]? = nil,
        contrastSafetyWarning: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.riskTier = riskTier
        self.confidenceScore = confidenceScore
        self.crtMeasurement = crtMeasurement
        self.limbScanData = limbScanData
        self.patientProfile = patientProfile
        
        // Populate default tailored recommendations if none supplied
        if let primaryRecommendation = primaryRecommendation {
            self.primaryRecommendation = primaryRecommendation
        } else {
            switch riskTier {
            case .low:
                self.primaryRecommendation = "Reassurance & Routine Follow-up: Encourage regular daily walking (supervised exercise therapy) and maintain glycemic/blood pressure control."
            case .moderate:
                self.primaryRecommendation = "Outpatient Vascular Consultation: Non-urgent arterial duplex ultrasound recommended. Optimize antiplatelet and statin medical therapy."
            case .critical:
                self.primaryRecommendation = "IMMEDIATE VASCULAR SURGERY REFERRAL: Urgent Doppler ultrasound and bedside perfusion re-assessment to prevent imminent limb loss."
            }
        }
        
        if let detailedClinicalNotes = detailedClinicalNotes {
            self.detailedClinicalNotes = detailedClinicalNotes
        } else {
            var notes: [String] = []
            if let crt = crtMeasurement {
                notes.append("Digital CRT: \(String(format: "%.2f", crt.crtSeconds))s (\(crt.clinicalTier.localizedName))")
            }
            if let limb = limbScanData {
                notes.append("Calf Circumference Asymmetry: \(String(format: "%.1f", limb.calfAsymmetryPct))% (\(limb.affectedLimbDescription))")
            }
            if patientProfile.restPainScore >= 5 {
                notes.append("Rest Pain: Score \(patientProfile.restPainScore)/10 (Consistent with ischemic nocturnal rest pain)")
            }
            if patientProfile.claudicationDistanceMeters < 100 {
                notes.append("Claudication Distance: \(Int(patientProfile.claudicationDistanceMeters))m (Severe functional walking impairment)")
            }
            self.detailedClinicalNotes = notes
        }
        
        if let contrastSafetyWarning = contrastSafetyWarning {
            self.contrastSafetyWarning = contrastSafetyWarning
        } else {
            if patientProfile.hasCKD {
                self.contrastSafetyWarning = "CONTRAST-INDUCED NEPHROPATHY (CIN) ALERT: Patient has confirmed CKD stage 3-5 or dialysis dependency. AVOID standard iodinated/gadolinium contrast angiography. Prioritize non-contrast duplex ultrasound or non-contrast MRA."
            } else {
                self.contrastSafetyWarning = "Screening performed using non-invasive optical and LiDAR sensors. Zero ionizing radiation and zero chemical contrast administered."
            }
        }
    }
    
    // MARK: - Mock Generator
    
    public static func sampleMock(tier: RiskTier = .critical) -> RiskReport {
        let crt = CRTMeasurement.sampleMock(isAbnormal: tier == .critical)
        let limb = LimbScanData.sampleMock(isAsymmetric: tier != .low)
        let profile = (tier == .critical) ? PatientProfile.elderlyDialysisPatient : PatientProfile.standardHealthyAdult
        
        return RiskReport(
            riskTier: tier,
            confidenceScore: tier == .critical ? 0.94 : 0.88,
            crtMeasurement: crt,
            limbScanData: limb,
            patientProfile: profile
        )
    }
}
