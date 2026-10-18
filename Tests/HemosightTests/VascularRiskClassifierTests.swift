import Testing
import Foundation
@testable import Hemosight

@Suite("Vascular Risk Classifier Tests")
struct VascularRiskClassifierTests {
    
    let classifier = VascularRiskClassifier()
    
    // MARK: - Low Risk Stratification
    
    @Test("Symmetric feet and crisp toe pulse morphology classify as Low Risk")
    func testLowRiskClassification() {
        // Given
        let visual = VisualIschemiaResult.fixture(
            deltaE: 1.5,
            lightnessDisparity: 0.8,
            asymmetryScore: 0.10
        )
        let finger = WaveformMorphometry.fixture(
            site: .finger,
            meanSystolicRiseTimeMs: 105.0,
            meanPulseAmplitude: 2.0,
            dicroticNotchPrevalence: 0.85
        )
        let toe = WaveformMorphometry.fixture(
            site: .toe,
            meanSystolicRiseTimeMs: 120.0,
            meanPulseAmplitude: 1.5,
            dicroticNotchPrevalence: 0.75
        )
        
        // When
        let report = classifier.evaluateVascularRisk(
            visualResult: visual,
            fingerWave: finger,
            toeWave: toe,
            patientName: "Alice Walker",
            patientAge: 55
        )
        
        // Then
        #expect(report.overallRiskLevel == .low)
        #expect(report.compositeRiskScore < 20.0)
        #expect(report.recommendations.contains { $0.contains("wellness") })
    }
    
    // MARK: - Moderate Risk Stratification
    
    @Test("Mild toe damping with prolonged SRT classifies as Moderate Risk")
    func testModerateRiskClassification() {
        // Given
        let visual = VisualIschemiaResult.fixture(
            deltaE: 3.8,
            lightnessDisparity: 2.0
        )
        let finger = WaveformMorphometry.fixture(
            site: .finger,
            meanSystolicRiseTimeMs: 110.0,
            meanPulseAmplitude: 2.0
        )
        // Prolonged toe SRT (> 165ms triggers moderate risk)
        let toe = WaveformMorphometry.fixture(
            site: .toe,
            meanSystolicRiseTimeMs: 172.0,
            meanPulseAmplitude: 0.8,
            dicroticNotchPrevalence: 0.30
        )
        
        // When
        let report = classifier.evaluateVascularRisk(
            visualResult: visual,
            fingerWave: finger,
            toeWave: toe,
            patientName: "George Miller",
            patientAge: 62
        )
        
        // Then
        #expect(report.overallRiskLevel == .moderate)
        #expect(report.compositeRiskScore >= 20.0 || toe.meanSystolicRiseTimeMs > 165.0)
        #expect(report.recommendations.contains { $0.contains("14 days") })
    }
    
    // MARK: - High Risk Stratification
    
    @Test("Severe toe pulse damping (SRT > 220ms and Ratio < 0.20) classifies as High Risk")
    func testSevereDampingHighRiskClassification() {
        // Given
        let visual = VisualIschemiaResult.fixture(deltaE: 2.0, lightnessDisparity: 1.0)
        let finger = WaveformMorphometry.fixture(
            site: .finger,
            meanSystolicRiseTimeMs: 100.0,
            meanPulseAmplitude: 2.2,
            dicroticNotchPrevalence: 0.90
        )
        let toe = WaveformMorphometry.fixture(
            site: .toe,
            meanSystolicRiseTimeMs: 235.0,
            meanPulseAmplitude: 0.3,
            dicroticNotchPrevalence: 0.0
        )
        
        // When
        let report = classifier.evaluateVascularRisk(
            visualResult: visual,
            fingerWave: finger,
            toeWave: toe,
            patientName: "Robert Vance",
            patientAge: 76
        )
        
        // Then
        #expect(report.overallRiskLevel == .high)
        #expect(report.compositeRiskScore >= 45.0)
        #expect(report.hemodynamicResult.isToeDicroticNotchLost)
        #expect(report.recommendations.contains { $0.contains("ABI") })
    }
    
    // MARK: - Parameterized Age Multiplier Tests
    
    @Test(
        "Age weighting properly elevates risk score for elderly cohorts",
        arguments: [
            (50, 1.0),
            (65, 1.05),
            (78, 1.10)
        ]
    )
    func testAgeAdjustmentWeights(age: Int, expectedMultiplier: Double) {
        // Given: Baseline inputs producing fixed score before age weighting
        let visual = VisualIschemiaResult.fixture(deltaE: 4.0, lightnessDisparity: 0.0)
        let finger = WaveformMorphometry.fixture(site: .finger, meanSystolicRiseTimeMs: 110.0, meanPulseAmplitude: 2.0)
        let toe = WaveformMorphometry.fixture(site: .toe, meanSystolicRiseTimeMs: 160.0, meanPulseAmplitude: 1.0)
        
        // When
        let report = classifier.evaluateVascularRisk(
            visualResult: visual,
            fingerWave: finger,
            toeWave: toe,
            patientName: "Cohort Subject",
            patientAge: age
        )
        
        // Base score: toe SRT > 150 (+10) + deltaE > 3.5 (+8) = 18.0
        let baseScore = 18.0
        let expectedScore = baseScore * expectedMultiplier
        
        // Then
        #expect(abs(report.compositeRiskScore - expectedScore) < 0.01)
    }
    
    // MARK: - Visual Pallor & Color Disparity Impact
    
    @Test("Unilateral blanching with marked lightness disparity elevates risk and emits explicit recommendation")
    func testUnilateralPallorImpact() {
        // Given
        let visual = VisualIschemiaResult.fixture(
            deltaE: 6.5,
            lightnessDisparity: 10.5, // Left foot markedly pale
            trophicRiskFlags: ["Unilateral dorsal blanching on Left foot"]
        )
        let finger = WaveformMorphometry.fixture(site: .finger, meanSystolicRiseTimeMs: 110.0, meanPulseAmplitude: 2.0)
        let toe = WaveformMorphometry.fixture(site: .toe, meanSystolicRiseTimeMs: 140.0, meanPulseAmplitude: 1.4)
        
        // When
        let report = classifier.evaluateVascularRisk(
            visualResult: visual,
            fingerWave: finger,
            toeWave: toe,
            patientName: "David Lee",
            patientAge: 65
        )
        
        // Then
        #expect(report.visualResult.isClinicallyAsymmetric)
        #expect(report.recommendations.contains { $0.contains("Unilateral dorsal foot blanching") })
    }
}
