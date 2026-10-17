import Foundation

/// Represents a single digital Capillary Refill Time (CRT) recording session
/// extracted from high-speed RGB video stream of the patient's toe nailbed.
public struct CRTMeasurement: Identifiable, Codable, Sendable {
    public let id: UUID
    public let timestamp: Date
    
    /// Raw mean red channel values over time: I_R(t) = 1/N * sum(R)
    public let rawRedIntensities: [Double]
    
    /// Noise-filtered red channel values (moving average / vDSP smoothed)
    public let filteredRedIntensities: [Double]
    
    /// Pre-compression baseline optical reflectance intensity
    public let baselineIntensity: Double
    
    /// Minimum reflectance intensity during peak blanching compression
    public let minimumIntensity: Double
    
    /// 90% recovery target reflectance threshold
    public let recoveryThresholdIntensity: Double
    
    /// Elapsed capillary reperfusion duration in seconds: t_90% - t_release
    public let crtSeconds: Double
    
    /// Sampling frame rate used during capture (default 60 FPS)
    public let frameRate: Double
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        rawRedIntensities: [Double],
        filteredRedIntensities: [Double],
        baselineIntensity: Double,
        minimumIntensity: Double,
        recoveryThresholdIntensity: Double,
        crtSeconds: Double,
        frameRate: Double = 60.0
    ) {
        self.id = id
        self.timestamp = timestamp
        self.rawRedIntensities = rawRedIntensities
        self.filteredRedIntensities = filteredRedIntensities
        self.baselineIntensity = baselineIntensity
        self.minimumIntensity = minimumIntensity
        self.recoveryThresholdIntensity = recoveryThresholdIntensity
        self.crtSeconds = crtSeconds
        self.frameRate = frameRate
    }
    
    // MARK: - Clinical Classification
    
    public enum ClinicalTier: String, Codable, Sendable {
        case normal = "Normal Perfusion"
        case borderline = "Borderline / Mild Ischemia"
        case critical = "Critical Limb-Threatening Ischemia"
        
        public var localizedName: String { rawValue }
    }
    
    public var clinicalTier: ClinicalTier {
        if crtSeconds < 2.0 {
            return .normal
        } else if crtSeconds <= 4.0 {
            return .borderline
        } else {
            return .critical
        }
    }
    
    public var formattedCRT: String {
        String(format: "%.2f s", crtSeconds)
    }
    
    // MARK: - Mock Preview Generator
    
    public static func sampleMock(isAbnormal: Bool = false) -> CRTMeasurement {
        let count = 180 // 3 seconds at 60 FPS
        var raw: [Double] = []
        var filtered: [Double] = []
        
        let baseline = 0.82
        let minVal = 0.35
        let crtSec = isAbnormal ? 4.8 : 1.6
        let recoverySamples = Int(crtSec * 60.0)
        
        for i in 0..<count {
            let val: Double
            if i < 30 {
                // Baseline pre-compression
                val = baseline + Double.random(in: -0.015...0.015)
            } else if i < 60 {
                // Compression phase (drops to min)
                let progress = Double(i - 30) / 30.0
                val = baseline - (baseline - minVal) * progress + Double.random(in: -0.01...0.01)
            } else {
                // Release & recovery phase
                let releaseIdx = i - 60
                let recoveryProgress = min(1.0, Double(releaseIdx) / Double(max(1, recoverySamples)))
                // Sigmoidal reperfusion curve
                let sigmoid = 1.0 / (1.0 + exp(-6.0 * (recoveryProgress - 0.5)))
                val = minVal + (baseline - minVal) * sigmoid + Double.random(in: -0.01...0.01)
            }
            raw.append(val)
            filtered.append(val * 0.98 + baseline * 0.02)
        }
        
        let threshold = minVal + 0.90 * (baseline - minVal)
        
        return CRTMeasurement(
            rawRedIntensities: raw,
            filteredRedIntensities: filtered,
            baselineIntensity: baseline,
            minimumIntensity: minVal,
            recoveryThresholdIntensity: threshold,
            crtSeconds: crtSec
        )
    }
}
