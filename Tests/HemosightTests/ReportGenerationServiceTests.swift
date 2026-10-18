import Testing
import UIKit
import PDFKit
@testable import Hemosight

@Suite("Report Generation Service Tests")
struct ReportGenerationServiceTests {
    
    let service = ReportGenerationService()
    
    @Test("PDF generator creates non-empty valid PDF format data")
    func testValidPDFGeneration() throws {
        // Given
        let report = ComprehensivePADReport.fixture(
            overallRiskLevel: .low,
            compositeRiskScore: 12.0
        )
        let fingerSamples: [Float] = (0..<180).map { sin(Float($0) * 0.1) }
        let toeSamples: [Float] = (0..<180).map { sin(Float($0) * 0.1) * 0.7 }
        
        // When
        let pdfData = service.generatePDFReport(
            report: report,
            footImage: nil,
            fingerWaveformSamples: fingerSamples,
            toeWaveformSamples: toeSamples
        )
        
        // Then
        #expect(!pdfData.isEmpty)
        #expect(pdfData.count > 1024) // Multi-kilobyte PDF document
        
        // Verify standard PDF header "%PDF-"
        let header = String(decoding: pdfData.prefix(5), as: UTF8.self)
        #expect(header.starts(with: "%PDF"))
    }
    
    @Test("PDF generator gracefully handles nil foot image and empty waveform buffers")
    func testPDFGenerationWithEmptyWaveforms() {
        // Given
        let report = ComprehensivePADReport.fixture(
            overallRiskLevel: .high,
            compositeRiskScore: 68.0,
            recommendations: [
                "URGENT: Formal ABI testing needed",
                "Arterial Duplex Ultrasound recommended"
            ]
        )
        
        // When
        let pdfData = service.generatePDFReport(
            report: report,
            footImage: nil,
            fingerWaveformSamples: [],
            toeWaveformSamples: []
        )
        
        // Then
        #expect(!pdfData.isEmpty)
        let header = String(decoding: pdfData.prefix(5), as: UTF8.self)
        #expect(header.starts(with: "%PDF"))
    }
    
    @Test(
        "PDF generation supports all risk tier presentations",
        arguments: [
            PADRiskLevel.low,
            PADRiskLevel.moderate,
            PADRiskLevel.high
        ]
    )
    func testPDFGenerationAcrossRiskLevels(riskLevel: PADRiskLevel) {
        // Given
        let report = ComprehensivePADReport.fixture(
            overallRiskLevel: riskLevel,
            compositeRiskScore: riskLevel == .low ? 10.0 : (riskLevel == .moderate ? 30.0 : 70.0)
        )
        
        // When
        let pdfData = service.generatePDFReport(
            report: report,
            footImage: nil,
            fingerWaveformSamples: [0.1, 0.5, 1.0, 0.5, 0.1],
            toeWaveformSamples: [0.1, 0.3, 0.6, 0.3, 0.1]
        )
        
        // Then
        #expect(!pdfData.isEmpty)
    }
}
