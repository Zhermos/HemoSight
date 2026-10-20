import Foundation
import SwiftUI

// MARK: - Clinical Screening Models

/// Anatomical acquisition site for hemodynamic PPG comparison.
public enum PPGSite: String, Codable, Sendable, CaseIterable {
    case finger = "Fingertip (Cardiac Baseline)"
    case toe = "Distal Big Toe (Lower Extremity)"
}

/// Clinical risk stratification category according to hemodynamic & visual indicators.
public enum PADRiskLevel: String, Codable, Sendable {
    case low = "Low Risk (Normal)"
    case moderate = "Moderate Risk (Borderline)"
    case high = "High Risk (Ischemic Pattern Detected)"
    
    public var displayColor: Color {
        switch self {
        case .low: return Color.green
        case .moderate: return Color.orange
        case .high: return Color.red
        }
    }
    
    public var clinicalSummary: String {
        switch self {
        case .low:
            return "Normal bilateral foot symmetry and crisp, well-perfused distal toe pulse waveform."
        case .moderate:
            return "Borderline pulse damping or mild cutaneous asymmetry detected. Recommend follow-up re-test in 14 days."
        case .high:
            return "Significant distal pulse attenuation (damping/delayed systolic upstroke) or marked unilateral pallor. Immediate clinical referral for Ankle-Brachial Index (ABI) and Arterial Duplex Ultrasound strongly advised."
        }
    }
    
    public func localizedTitle(for language: AppLanguage) -> String {
        HemosightStrings.riskTierTitle(for: self, language: language)
    }
    
    public func localizedSummary(for language: AppLanguage) -> String {
        HemosightStrings.clinicalSummary(for: self, language: language)
    }
}

extension PPGSite {
    public func localizedTitle(for language: AppLanguage) -> String {
        HemosightStrings.ppgSiteTitle(for: self, language: language)
    }
    
    public func localizedInstruction(for language: AppLanguage) -> String {
        HemosightStrings.ppgInstruction(for: self, language: language)
    }
}


/// CIE L*a*b* Disparity and Computer Vision Pallor Assessment.
public struct VisualIschemiaResult: Codable, Sendable {
    /// Color difference (CIE Delta E 2000 or Euclidean approximation) between left and right foot dorsal ROIs.
    public let deltaE: Double
    /// Difference in Lightness channel (L* left - L* right). Higher value indicates unilateral blanching/pallor.
    public let lightnessDisparity: Double
    /// Average L* (Lightness) of left dorsal foot ROI.
    public let leftFootLightness: Double
    /// Average L* (Lightness) of right dorsal foot ROI.
    public let rightFootLightness: Double
    /// Asymmetry score normalized from 0.0 (perfectly symmetric) to 1.0 (severe asymmetry).
    public let asymmetryScore: Double
    /// Trophic skin change markers identified (e.g., loss of hair, shiny atrophic skin, localized pallor).
    public let trophicRiskFlags: [String]
    /// Whether significant ischemic pallor asymmetry is flagged.
    public var isClinicallyAsymmetric: Bool {
        return deltaE > 4.5 || abs(lightnessDisparity) > 8.0
    }
    
    public init(
        deltaE: Double,
        lightnessDisparity: Double,
        leftFootLightness: Double,
        rightFootLightness: Double,
        asymmetryScore: Double,
        trophicRiskFlags: [String] = []
    ) {
        self.deltaE = deltaE
        self.lightnessDisparity = lightnessDisparity
        self.leftFootLightness = leftFootLightness
        self.rightFootLightness = rightFootLightness
        self.asymmetryScore = asymmetryScore
        self.trophicRiskFlags = trophicRiskFlags
    }
}

/// Individual filtered PPG sample for real-time visualization & export.
public struct PPGDataPoint: Identifiable, Sendable, Codable {
    public let id: UUID
    public let timestamp: Double // Elapsed seconds from scan start
    public let filteredGreen: Float
    public let rawGreen: Float
    public let rawRed: Float
    
    public init(id: UUID = UUID(), timestamp: Double, filteredGreen: Float, rawGreen: Float, rawRed: Float) {
        self.id = id
        self.timestamp = timestamp
        self.filteredGreen = filteredGreen
        self.rawGreen = rawGreen
        self.rawRed = rawRed
    }
}

/// Morphometric features extracted from a 30-second pulsatile photoplethysmogram.
public struct WaveformMorphometry: Codable, Sendable {
    public let site: PPGSite
    /// Mean Systolic Rise Time (SRT) in milliseconds (foot-of-wave to systolic peak). Normal finger: ~90-130ms; Ischemic toe: >180ms.
    public let meanSystolicRiseTimeMs: Double
    /// Peak-to-peak pulse wave AC amplitude.
    public let meanPulseAmplitude: Double
    /// Percentage of pulses exhibiting an identifiable dicrotic notch (loss indicates severe downstream micro/macrovascular stiffness or damping).
    public let dicroticNotchPrevalence: Double
    /// Heart rate in beats per minute derived from peak intervals.
    public let estimatedBPM: Double
    /// Average Signal Quality Index (0.0 to 1.0) across the session.
    public let signalQualityIndex: Double
    
    public init(
        site: PPGSite,
        meanSystolicRiseTimeMs: Double,
        meanPulseAmplitude: Double,
        dicroticNotchPrevalence: Double,
        estimatedBPM: Double,
        signalQualityIndex: Double
    ) {
        self.site = site
        self.meanSystolicRiseTimeMs = meanSystolicRiseTimeMs
        self.meanPulseAmplitude = meanPulseAmplitude
        self.dicroticNotchPrevalence = dicroticNotchPrevalence
        self.estimatedBPM = estimatedBPM
        self.signalQualityIndex = signalQualityIndex
    }
}

/// Comparative Hemodynamic findings between Central (Finger) and Distal (Toe).
public struct HemodynamicComparisonResult: Codable, Sendable {
    public let fingerMorphometry: WaveformMorphometry
    public let toeMorphometry: WaveformMorphometry
    /// Ratio of Toe AC Amplitude to Finger AC Amplitude (Toe Amplitude / Finger Amplitude). Significant damping < 0.35.
    public let amplitudeRatio: Double
    /// Difference in Systolic Rise Time (Toe SRT - Finger SRT) in ms.
    public let srtDelayMs: Double
    /// Loss of dicrotic notch at toe compared to preserved finger notch.
    public let isToeDicroticNotchLost: Bool
    
    public var isHemodynamicallyAbnormal: Bool {
        return toeMorphometry.meanSystolicRiseTimeMs > 180.0 || amplitudeRatio < 0.35 || srtDelayMs > 60.0
    }
}

/// Holistic clinical screening outcome aggregating computer vision and hemodynamic modalities.
public struct ComprehensivePADReport: Codable, Sendable {
    public let reportID: UUID
    public let patientName: String
    public let patientAge: Int
    public let timestamp: Date
    public let visualResult: VisualIschemiaResult?
    public let hemodynamicResult: HemodynamicComparisonResult
    public let overallRiskLevel: PADRiskLevel
    public let compositeRiskScore: Double // 0.0 to 100.0 scale
    public let recommendations: [String]
    
    public init(
        reportID: UUID = UUID(),
        patientName: String,
        patientAge: Int,
        timestamp: Date = Date(),
        visualResult: VisualIschemiaResult? = nil,
        hemodynamicResult: HemodynamicComparisonResult,
        overallRiskLevel: PADRiskLevel,
        compositeRiskScore: Double,
        recommendations: [String]
    ) {
        self.reportID = reportID
        self.patientName = patientName
        self.patientAge = patientAge
        self.timestamp = timestamp
        self.visualResult = visualResult
        self.hemodynamicResult = hemodynamicResult
        self.overallRiskLevel = overallRiskLevel
        self.compositeRiskScore = compositeRiskScore
        self.recommendations = recommendations
    }
}

// MARK: - Test Fixtures (F.I.R.S.T. Compliant)

#if DEBUG
extension VisualIschemiaResult {
    public static func fixture(
        deltaE: Double = 1.2,
        lightnessDisparity: Double = 0.5,
        leftFootLightness: Double = 65.0,
        rightFootLightness: Double = 64.5,
        asymmetryScore: Double = 0.08,
        trophicRiskFlags: [String] = []
    ) -> VisualIschemiaResult {
        VisualIschemiaResult(
            deltaE: deltaE,
            lightnessDisparity: lightnessDisparity,
            leftFootLightness: leftFootLightness,
            rightFootLightness: rightFootLightness,
            asymmetryScore: asymmetryScore,
            trophicRiskFlags: trophicRiskFlags
        )
    }
}

extension PPGDataPoint {
    public static func fixture(
        id: UUID = UUID(),
        timestamp: Double = 0.5,
        filteredGreen: Float = 120.0,
        rawGreen: Float = 120.5,
        rawRed: Float = 210.0
    ) -> PPGDataPoint {
        PPGDataPoint(
            id: id,
            timestamp: timestamp,
            filteredGreen: filteredGreen,
            rawGreen: rawGreen,
            rawRed: rawRed
        )
    }
}

extension WaveformMorphometry {
    public static func fixture(
        site: PPGSite = .finger,
        meanSystolicRiseTimeMs: Double = 110.0,
        meanPulseAmplitude: Double = 1.8,
        dicroticNotchPrevalence: Double = 0.85,
        estimatedBPM: Double = 72.0,
        signalQualityIndex: Double = 0.95
    ) -> WaveformMorphometry {
        WaveformMorphometry(
            site: site,
            meanSystolicRiseTimeMs: meanSystolicRiseTimeMs,
            meanPulseAmplitude: meanPulseAmplitude,
            dicroticNotchPrevalence: dicroticNotchPrevalence,
            estimatedBPM: estimatedBPM,
            signalQualityIndex: signalQualityIndex
        )
    }
}

extension HemodynamicComparisonResult {
    public static func fixture(
        fingerMorphometry: WaveformMorphometry = .fixture(site: .finger),
        toeMorphometry: WaveformMorphometry = .fixture(
            site: .toe,
            meanSystolicRiseTimeMs: 125.0,
            meanPulseAmplitude: 1.2,
            dicroticNotchPrevalence: 0.70
        ),
        amplitudeRatio: Double = 0.67,
        srtDelayMs: Double = 15.0,
        isToeDicroticNotchLost: Bool = false
    ) -> HemodynamicComparisonResult {
        HemodynamicComparisonResult(
            fingerMorphometry: fingerMorphometry,
            toeMorphometry: toeMorphometry,
            amplitudeRatio: amplitudeRatio,
            srtDelayMs: srtDelayMs,
            isToeDicroticNotchLost: isToeDicroticNotchLost
        )
    }
}

extension ComprehensivePADReport {
    public static func fixture(
        reportID: UUID = UUID(),
        patientName: String = "Test Patient",
        patientAge: Int = 65,
        timestamp: Date = Date(timeIntervalSince1970: 1700000000), // Fixed repeatable date per F.I.R.S.T.
        visualResult: VisualIschemiaResult? = nil,
        hemodynamicResult: HemodynamicComparisonResult = .fixture(),
        overallRiskLevel: PADRiskLevel = .low,
        compositeRiskScore: Double = 12.0,
        recommendations: [String] = ["Normal bilateral perfusion findings."]
    ) -> ComprehensivePADReport {
        ComprehensivePADReport(
            reportID: reportID,
            patientName: patientName,
            patientAge: patientAge,
            timestamp: timestamp,
            visualResult: visualResult,
            hemodynamicResult: hemodynamicResult,
            overallRiskLevel: overallRiskLevel,
            compositeRiskScore: compositeRiskScore,
            recommendations: recommendations
        )
    }
}
#endif

