import Foundation
import CoreML

/// Classifies vascular PAD risk by synthesizing Computer Vision visual pallor asymmetry and Dual-Site PPG morphometry.
public final class VascularRiskClassifier: Sendable {
    
    public init() {}
    
    /// Computes the comprehensive screening outcome.
    /// - Parameters:
    ///   - visualResult: Quantified CIE L*a*b* asymmetry, Delta E, and pallor metrics.
    ///   - fingerWave: Extracted morphometry from fingertip baseline.
    ///   - toeWave: Extracted morphometry from distal big toe.
    ///   - patientName: Patient or subject identifier.
    ///   - patientAge: Age in years.
    /// - Returns: Complete `ComprehensivePADReport`.
    public func evaluateVascularRisk(
        visualResult: VisualIschemiaResult,
        fingerWave: WaveformMorphometry,
        toeWave: WaveformMorphometry,
        patientName: String,
        patientAge: Int
    ) -> ComprehensivePADReport {
        
        // 1. Calculate Hemodynamic Comparison Parameters
        let toeAmplitude = max(0.001, toeWave.meanPulseAmplitude)
        let fingerAmplitude = max(0.001, fingerWave.meanPulseAmplitude)
        let amplitudeRatio = toeAmplitude / fingerAmplitude
        
        let srtDelay = toeWave.meanSystolicRiseTimeMs - fingerWave.meanSystolicRiseTimeMs
        let toeNotchAbsent = toeWave.dicroticNotchPrevalence < 0.15 && fingerWave.dicroticNotchPrevalence > 0.40
        
        let hemodynamicResult = HemodynamicComparisonResult(
            fingerMorphometry: fingerWave,
            toeMorphometry: toeWave,
            amplitudeRatio: amplitudeRatio,
            srtDelayMs: srtDelay,
            isToeDicroticNotchLost: toeNotchAbsent
        )
        
        // 2. Multi-Parametric Scoring Engine
        // Base Score = 0 (completely healthy) to 100 (critical ischemia)
        var compositeScore: Double = 0.0
        var recommendations: [String] = []
        
        // --- Hemodynamic Metric 1: Toe Systolic Rise Time (SRT) ---
        // Normal: 90 - 140 ms. Delayed (>180 ms) indicates proximal arterial stenosis or severe damping.
        if toeWave.meanSystolicRiseTimeMs > 220.0 {
            compositeScore += 35.0
            recommendations.append("Severe pulse upstroke delay detected at toe (SRT > 220 ms), characteristic of proximal arterial stenosis.")
        } else if toeWave.meanSystolicRiseTimeMs > 180.0 {
            compositeScore += 22.0
            recommendations.append("Prolonged toe systolic rise time (> 180 ms) suggesting peripheral vascular damping.")
        } else if toeWave.meanSystolicRiseTimeMs > 150.0 {
            compositeScore += 10.0
        }
        
        // --- Hemodynamic Metric 2: Toe-to-Finger Amplitude Ratio ---
        // Normal: > 0.50. Damped: < 0.35. Severe microcirculatory deficiency: < 0.20.
        if amplitudeRatio < 0.20 {
            compositeScore += 30.0
            recommendations.append("Marked attenuation of distal microcirculatory pulse volume (Toe-to-Finger Ratio < 0.20).")
        } else if amplitudeRatio < 0.35 {
            compositeScore += 18.0
            recommendations.append("Diminished pulse amplitude ratio (< 0.35) observed between finger and toe.")
        }
        
        // --- Hemodynamic Metric 3: Loss of Dicrotic Notch ---
        if toeNotchAbsent {
            compositeScore += 12.0
            recommendations.append("Blunted toe waveform with complete disappearance of the dicrotic wave notch.")
        }
        
        // --- Visual Metric 1: CIE L*a*b* Color Difference (Delta E) ---
        // Delta E > 5.0 indicates noticeable bilateral skin color mismatch.
        if visualResult.deltaE > 6.0 {
            compositeScore += 18.0
            recommendations.append("Pronounced bilateral cutaneous chromatic discrepancy (Delta E = \(String(format: "%.1f", visualResult.deltaE))).")
        } else if visualResult.deltaE > 3.5 {
            compositeScore += 8.0
        }
        
        // --- Visual Metric 2: Unilateral Pallor (L* Disparity) ---
        if abs(visualResult.lightnessDisparity) > 8.0 {
            let paleSide = visualResult.lightnessDisparity > 0 ? "Left" : "Right"
            compositeScore += 15.0
            recommendations.append("Unilateral dorsal foot blanching / pallor on the \(paleSide) foot.")
        }
        
        // --- Age-Adjusted Risk Weighting ---
        if patientAge >= 70 {
            compositeScore *= 1.10
        } else if patientAge >= 60 {
            compositeScore *= 1.05
        }
        
        // Clamp score between 0 and 100
        compositeScore = min(100.0, max(0.0, compositeScore))
        
        // 3. Risk Stratification Categorization
        let riskLevel: PADRiskLevel
        if compositeScore >= 45.0 || toeWave.meanSystolicRiseTimeMs > 200.0 || (amplitudeRatio < 0.25 && visualResult.deltaE > 5.0) {
            riskLevel = .high
            recommendations.insert("URGENT: Schedule in-person clinical evaluation for formal Ankle-Brachial Index (ABI) and Arterial Duplex Ultrasound.", at: 0)
        } else if compositeScore >= 20.0 || toeWave.meanSystolicRiseTimeMs > 165.0 || visualResult.deltaE > 4.0 {
            riskLevel = .moderate
            recommendations.insert("RECOMMENDED: Repeat Hemosight screening in 14 days and monitor for calf cramping / claudication during walking.", at: 0)
        } else {
            riskLevel = .low
            recommendations.insert("Normal bilateral perfusion findings. Continue routine cardiovascular wellness and foot skin hygiene.", at: 0)
        }
        
        return ComprehensivePADReport(
            patientName: patientName,
            patientAge: patientAge,
            timestamp: Date(),
            visualResult: visualResult,
            hemodynamicResult: hemodynamicResult,
            overallRiskLevel: riskLevel,
            compositeRiskScore: compositeScore,
            recommendations: recommendations
        )
    }
}
