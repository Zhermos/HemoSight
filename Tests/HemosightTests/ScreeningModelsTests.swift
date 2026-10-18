import Testing
import Foundation
import SwiftUI
@testable import Hemosight

@Suite("Clinical Screening Domain Models Tests")
struct ScreeningModelsTests {
    
    // MARK: - Visual Ischemia Result Tests
    
    @Test("Symmetric feet with low deltaE and minimal lightness disparity evaluates as clinically symmetric")
    func testSymmetricVisualResult() {
        // Given
        let visual = VisualIschemiaResult.fixture(
            deltaE: 1.8,
            lightnessDisparity: 1.2,
            leftFootLightness: 62.0,
            rightFootLightness: 60.8,
            asymmetryScore: 0.12
        )
        
        // When & Then
        #expect(!visual.isClinicallyAsymmetric)
        #expect(visual.deltaE < 4.5)
        #expect(abs(visual.lightnessDisparity) <= 8.0)
    }
    
    @Test(
        "Asymmetry triggers when deltaE > 4.5 or |lightnessDisparity| > 8.0",
        arguments: [
            (5.0, 2.0, true),
            (2.0, 9.5, true),
            (2.0, -8.5, true),
            (3.0, 4.0, false)
        ]
    )
    func testVisualAsymmetryParameterized(deltaE: Double, lightnessDisparity: Double, expectedAsymmetry: Bool) {
        // Given
        let visual = VisualIschemiaResult.fixture(
            deltaE: deltaE,
            lightnessDisparity: lightnessDisparity
        )
        
        // When
        let isAsymmetric = visual.isClinicallyAsymmetric
        
        // Then
        #expect(isAsymmetric == expectedAsymmetry)
    }
    
    // MARK: - PAD Risk Level Presentation Tests
    
    @Test("Risk level provides corresponding visual UI colors and clinical guidance summaries")
    func testRiskLevelDisplayProperties() {
        // Given & When & Then
        let low = PADRiskLevel.low
        #expect(low.displayColor == Color.green)
        #expect(low.clinicalSummary.contains("Normal bilateral foot symmetry"))
        
        let moderate = PADRiskLevel.moderate
        #expect(moderate.displayColor == Color.orange)
        #expect(moderate.clinicalSummary.contains("14 days"))
        
        let high = PADRiskLevel.high
        #expect(high.displayColor == Color.red)
        #expect(high.clinicalSummary.contains("Ankle-Brachial Index"))
    }
    
    // MARK: - Hemodynamic Comparison Tests
    
    @Test("Normal hemodynamics with preserved toe pulse is not flagged abnormal")
    func testNormalHemodynamicComparison() {
        // Given
        let finger = WaveformMorphometry.fixture(site: .finger, meanSystolicRiseTimeMs: 110.0, meanPulseAmplitude: 2.0)
        let toe = WaveformMorphometry.fixture(site: .toe, meanSystolicRiseTimeMs: 125.0, meanPulseAmplitude: 1.4)
        
        // When
        let comparison = HemodynamicComparisonResult.fixture(
            fingerMorphometry: finger,
            toeMorphometry: toe,
            amplitudeRatio: 0.70,
            srtDelayMs: 15.0,
            isToeDicroticNotchLost: false
        )
        
        // Then
        #expect(!comparison.isHemodynamicallyAbnormal)
        #expect(!comparison.isToeDicroticNotchLost)
    }
    
    @Test(
        "Hemodynamic abnormality triggers when toe SRT > 180ms, ratio < 0.35, or delay > 60ms",
        arguments: [
            (190.0, 0.60, 20.0, true),  // Prolonged toe SRT
            (120.0, 0.25, 10.0, true),  // Damped amplitude ratio
            (140.0, 0.60, 75.0, true),  // Excessive SRT delay
            (130.0, 0.55, 25.0, false)  // Completely normal
        ]
    )
    func testHemodynamicAbnormalityTriggers(
        toeSRT: Double,
        amplitudeRatio: Double,
        srtDelay: Double,
        expectedAbnormal: Bool
    ) {
        // Given
        let toe = WaveformMorphometry.fixture(site: .toe, meanSystolicRiseTimeMs: toeSRT)
        let comparison = HemodynamicComparisonResult.fixture(
            toeMorphometry: toe,
            amplitudeRatio: amplitudeRatio,
            srtDelayMs: srtDelay
        )
        
        // When & Then
        #expect(comparison.isHemodynamicallyAbnormal == expectedAbnormal)
    }
    
    // MARK: - Comprehensive Report Fixture Verification
    
    @Test("Report fixture produces stable, repeatable fields compliant with F.I.R.S.T.")
    func testReportFixtureDeterminism() throws {
        // Given & When
        let report = ComprehensivePADReport.fixture(
            patientName: "Alice Walker",
            patientAge: 68,
            overallRiskLevel: .low,
            compositeRiskScore: 14.5
        )
        
        // Then (Hard assertion for non-empty ID and soft assertions for values)
        let reportID = try #require(report.reportID)
        #expect(!reportID.uuidString.isEmpty)
        #expect(report.patientName == "Alice Walker")
        #expect(report.patientAge == 68)
        #expect(report.overallRiskLevel == .low)
        #expect(report.compositeRiskScore == 14.5)
        #expect(report.timestamp.timeIntervalSince1970 == 1700000000)
    }
}
