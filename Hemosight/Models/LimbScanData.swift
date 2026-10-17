import Foundation

/// 3D Morphometry scan record capturing bilateral lower limb measurements
/// extracted from ARKit scene reconstruction depth mesh slices.
public struct LimbScanData: Identifiable, Codable, Sendable {
    public let id: UUID
    public let timestamp: Date
    
    // Left Limb Measurements (in centimeters)
    public let leftAnkleCircumferenceCm: Double
    public let leftCalfCircumferenceCm: Double
    public let leftEstimatedVolumeCm3: Double
    
    // Right Limb Measurements (in centimeters)
    public let rightAnkleCircumferenceCm: Double
    public let rightCalfCircumferenceCm: Double
    public let rightEstimatedVolumeCm3: Double
    
    // Asymmetry Metrics
    /// Delta percentage at maximum calf girth: |C_affected - C_contralateral| / C_contralateral * 100%
    public let calfAsymmetryPct: Double
    
    /// Delta percentage at malleolus ankle level
    public let ankleAsymmetryPct: Double
    
    /// Number of 3D mesh polygon vertices sampled during slice integration
    public let meshVertexCount: Int
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        leftAnkleCircumferenceCm: Double,
        leftCalfCircumferenceCm: Double,
        leftEstimatedVolumeCm3: Double = 0.0,
        rightAnkleCircumferenceCm: Double,
        rightCalfCircumferenceCm: Double,
        rightEstimatedVolumeCm3: Double = 0.0,
        meshVertexCount: Int = 12400
    ) {
        self.id = id
        self.timestamp = timestamp
        self.leftAnkleCircumferenceCm = leftAnkleCircumferenceCm
        self.leftCalfCircumferenceCm = leftCalfCircumferenceCm
        self.leftEstimatedVolumeCm3 = leftEstimatedVolumeCm3
        self.rightAnkleCircumferenceCm = rightAnkleCircumferenceCm
        self.rightCalfCircumferenceCm = rightCalfCircumferenceCm
        self.rightEstimatedVolumeCm3 = rightEstimatedVolumeCm3
        self.meshVertexCount = meshVertexCount
        
        // Calculate calf asymmetry relative to maximum baseline limb
        let baselineCalf = max(leftCalfCircumferenceCm, rightCalfCircumferenceCm)
        if baselineCalf > 0.0 {
            self.calfAsymmetryPct = (abs(leftCalfCircumferenceCm - rightCalfCircumferenceCm) / baselineCalf) * 100.0
        } else {
            self.calfAsymmetryPct = 0.0
        }
        
        let baselineAnkle = max(leftAnkleCircumferenceCm, rightAnkleCircumferenceCm)
        if baselineAnkle > 0.0 {
            self.ankleAsymmetryPct = (abs(leftAnkleCircumferenceCm - rightAnkleCircumferenceCm) / baselineAnkle) * 100.0
        } else {
            self.ankleAsymmetryPct = 0.0
        }
    }
    
    // MARK: - Clinical Evaluation
    
    /// Whether calf circumference asymmetry exceeds the 8.0% clinical diagnostic threshold
    public var hasSignificantAsymmetry: Bool {
        calfAsymmetryPct > 8.0
    }
    
    /// Identification of potentially atrophic or edematous limb
    public var affectedLimbDescription: String {
        if !hasSignificantAsymmetry {
            return "Bilateral Symmetry Preserved (< 8.0%)"
        }
        if leftCalfCircumferenceCm < rightCalfCircumferenceCm {
            return String(format: "Left Calf Atrophy (-%.1f%%)", calfAsymmetryPct)
        } else {
            return String(format: "Right Calf Atrophy (-%.1f%%)", calfAsymmetryPct)
        }
    }
    
    // MARK: - Mock Preview Generator
    
    public static func sampleMock(isAsymmetric: Bool = false) -> LimbScanData {
        if isAsymmetric {
            return LimbScanData(
                leftAnkleCircumferenceCm: 21.2,
                leftCalfCircumferenceCm: 32.1,
                leftEstimatedVolumeCm3: 2150.0,
                rightAnkleCircumferenceCm: 23.8,
                rightCalfCircumferenceCm: 36.4,
                rightEstimatedVolumeCm3: 2580.0,
                meshVertexCount: 18450
            )
        } else {
            return LimbScanData(
                leftAnkleCircumferenceCm: 22.4,
                leftCalfCircumferenceCm: 35.8,
                leftEstimatedVolumeCm3: 2480.0,
                rightAnkleCircumferenceCm: 22.6,
                rightCalfCircumferenceCm: 36.0,
                rightEstimatedVolumeCm3: 2510.0,
                meshVertexCount: 16200
            )
        }
    }
}
