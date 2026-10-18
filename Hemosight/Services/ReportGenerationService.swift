import Foundation
import UIKit
import PDFKit

/// Protocol abstracting clinical PDF report generation for dependency injection and testing.
@MainActor
public protocol ReportGenerationServiceProtocol: Sendable {
    func generatePDFReport(
        report: ComprehensivePADReport,
        footImage: UIImage?,
        fingerWaveformSamples: [Float],
        toeWaveformSamples: [Float],
        language: AppLanguage
    ) -> Data
}

extension ReportGenerationServiceProtocol {
    public func generatePDFReport(
        report: ComprehensivePADReport,
        footImage: UIImage?,
        fingerWaveformSamples: [Float],
        toeWaveformSamples: [Float]
    ) -> Data {
        generatePDFReport(
            report: report,
            footImage: footImage,
            fingerWaveformSamples: fingerWaveformSamples,
            toeWaveformSamples: toeWaveformSamples,
            language: .english
        )
    }
}

/// Generates a standardized, professional 1-page clinical PDF summary for primary care physicians or vascular specialists.
@MainActor
public final class ReportGenerationService: ReportGenerationServiceProtocol, Sendable {
    
    public init() {}
    
    /// Generates a PDF Data object conforming to the 1-page clinical PAD screening report specification.
    public func generatePDFReport(
        report: ComprehensivePADReport,
        footImage: UIImage?,
        fingerWaveformSamples: [Float],
        toeWaveformSamples: [Float],
        language: AppLanguage = .english
    ) -> Data {
        
        let pdfTitle = (language == .thai)
            ? "สรุปผลการตรวจคัดกรองโรคหลอดเลือดแดงส่วนปลาย (Clinical PAD Screening Summary)"
            : "Clinical Peripheral Artery Disease Screening Summary"
        
        let pdfMetaData = [
            kCGPDFContextCreator: "Hemosight v1.0",
            kCGPDFContextAuthor: "Hemosight Clinical Screening Engine",
            kCGPDFContextTitle: pdfTitle
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        // Standard US Letter dimensions (8.5 x 11 inches at 72 DPI)
        let pageWidth: CGFloat = 612.0
        let pageHeight: CGFloat = 792.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            var cursorY: CGFloat = 36.0
            let marginX: CGFloat = 36.0
            let contentWidth = pageWidth - (2 * marginX)
            
            // 1. Header Banner
            let headerRect = CGRect(x: marginX, y: cursorY, width: contentWidth, height: 44.0)
            let headerStyle = NSMutableParagraphStyle()
            headerStyle.alignment = .left
            if language == .thai {
                headerStyle.lineSpacing = 3.0
            }
            
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: language.uiFont(size: 19, weight: .bold),
                .foregroundColor: UIColor.systemBlue,
                .paragraphStyle: headerStyle
            ]
            let mainHeaderTitle = (language == .thai)
                ? "HEMOSIGHT™ | สรุปผลการตรวจคัดกรองหลอดเลือดส่วนปลาย"
                : "HEMOSIGHT™ | Clinical Vascular Screening Summary"
            mainHeaderTitle.draw(in: headerRect, withAttributes: titleAttributes)
            cursorY += 28.0
            
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: language.uiFont(size: 10, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let dateStr = DateFormatter.localizedString(from: report.timestamp, dateStyle: .medium, timeStyle: .short)
            let subtitle = (language == .thai)
                ? "Dual-Site PPG & การประมวลผลภาพความสมดุลของสีผิว  •  สร้างเมื่อ: \(dateStr)"
                : "Dual-Site Photoplethysmography & Computer Vision Pallor Analysis  •  Generated: \(dateStr)"
            subtitle.draw(
                in: CGRect(x: marginX, y: cursorY, width: contentWidth, height: 16),
                withAttributes: subtitleAttributes
            )
            cursorY += 24.0
            
            // Divider
            drawDivider(y: cursorY, width: contentWidth, marginX: marginX)
            cursorY += 12.0
            
            // 2. Patient Demographics & Risk Stratification Card
            let cardHeight: CGFloat = 64.0
            let cardRect = CGRect(x: marginX, y: cursorY, width: contentWidth, height: cardHeight)
            let cardColor: UIColor
            switch report.overallRiskLevel {
            case .low: cardColor = UIColor.systemGreen.withAlphaComponent(0.12)
            case .moderate: cardColor = UIColor.systemOrange.withAlphaComponent(0.12)
            case .high: cardColor = UIColor.systemRed.withAlphaComponent(0.12)
            }
            let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 8)
            cardColor.setFill()
            cardPath.fill()
            
            let patientInfo = (language == .thai)
                ? "ผู้รับการตรวจ: \(report.patientName)   |   อายุ: \(report.patientAge) ปี   |   รหัสรายงาน: \(report.reportID.uuidString.prefix(8))"
                : "Patient: \(report.patientName)   |   Age: \(report.patientAge) yrs   |   ID: \(report.reportID.uuidString.prefix(8))"
            patientInfo.draw(
                in: CGRect(x: marginX + 12, y: cursorY + 10, width: contentWidth - 24, height: 18),
                withAttributes: [.font: language.uiFont(size: 11, weight: .semibold), .foregroundColor: UIColor.darkGray]
            )
            
            let riskTitle = (language == .thai)
                ? "สถานะความเสี่ยง: \(report.overallRiskLevel.localizedTitle(for: .thai).uppercased())  (คะแนน: \(Int(report.compositeRiskScore))/100)"
                : "OVERALL STATUS: \(report.overallRiskLevel.rawValue.uppercased())  (Risk Score: \(Int(report.compositeRiskScore))/100)"
            let riskColor: UIColor
            switch report.overallRiskLevel {
            case .low: riskColor = UIColor.systemGreen
            case .moderate: riskColor = UIColor.systemOrange
            case .high: riskColor = UIColor.systemRed
            }
            riskTitle.draw(
                in: CGRect(x: marginX + 12, y: cursorY + 32, width: contentWidth - 24, height: 22),
                withAttributes: [.font: language.uiFont(size: 13, weight: .bold), .foregroundColor: riskColor]
            )
            cursorY += cardHeight + 14.0
            
            // 3. Modality 1: Bilateral Foot Visual Inspection
            let sectionHeaderAttr: [NSAttributedString.Key: Any] = [
                .font: language.uiFont(size: 13, weight: .bold),
                .foregroundColor: UIColor.label
            ]
            let section1Title = (language == .thai)
                ? "1. การวิเคราะห์ภาพถ่ายหลังเท้าทั้งสองข้าง (Vision & CIE L*a*b*)"
                : "1. Bilateral Dorsal Foot Visual Chromaticity (Vision & CIE L*a*b*)"
            section1Title.draw(
                in: CGRect(x: marginX, y: cursorY, width: contentWidth, height: 18),
                withAttributes: sectionHeaderAttr
            )
            cursorY += 22.0
            
            let photoWidth: CGFloat = 140.0
            let photoHeight: CGFloat = 90.0
            let photoRect = CGRect(x: marginX, y: cursorY, width: photoWidth, height: photoHeight)
            
            if let img = footImage {
                img.draw(in: photoRect)
            } else {
                let placeholderPath = UIBezierPath(roundedRect: photoRect, cornerRadius: 4)
                UIColor.systemGray5.setFill()
                placeholderPath.fill()
                let photoPlaceholder = (language == .thai) ? "ภาพหลังเท้า" : "Foot Photo"
                photoPlaceholder.draw(
                    in: CGRect(x: marginX + 25, y: cursorY + 36, width: 90, height: 20),
                    withAttributes: [.font: language.uiFont(size: 11), .foregroundColor: UIColor.secondaryLabel]
                )
            }
            
            let metricsX = marginX + photoWidth + 16.0
            let metricsWidth = contentWidth - photoWidth - 16.0
            var metricY = cursorY
            
            let visMetrics: [(String, String)]
            if language == .thai {
                visMetrics = [
                    ("ความไม่สมมาตรของสีผิว (CIE ΔE):", String(format: "%.2f (ปกติ < 3.5)", report.visualResult.deltaE)),
                    ("ระดับความซีด (ΔL*):", String(format: "%+.1f L* (ซ้าย: %.1f vs ขวา: %.1f)", report.visualResult.lightnessDisparity, report.visualResult.leftFootLightness, report.visualResult.rightFootLightness)),
                    ("ภาวะซีดขาวเฉพาะข้าง:", report.visualResult.isClinicallyAsymmetric ? "ตรวจพบ (DETECTED)" : "ไม่พบ (None)"),
                    ("สัญญาณการเสื่อมของเนื้อเยื่อ:", report.visualResult.trophicRiskFlags.isEmpty ? "ไม่พบสัญญาณผิดปกติ" : report.visualResult.trophicRiskFlags.joined(separator: ", "))
                ]
            } else {
                visMetrics = [
                    ("Bilateral Color Disparity (CIE ΔE):", String(format: "%.2f (Normal < 3.5)", report.visualResult.deltaE)),
                    ("Lightness Disparity (ΔL*):", String(format: "%+.1f L* (Left: %.1f vs Right: %.1f)", report.visualResult.lightnessDisparity, report.visualResult.leftFootLightness, report.visualResult.rightFootLightness)),
                    ("Unilateral Blanching / Pallor:", report.visualResult.isClinicallyAsymmetric ? "DETECTED" : "None"),
                    ("Trophic Risk Flags:", report.visualResult.trophicRiskFlags.isEmpty ? "No abnormal trophic signs" : report.visualResult.trophicRiskFlags.joined(separator: ", "))
                ]
            }
            
            for (title, val) in visMetrics {
                let lineText = "\(title) \(val)"
                lineText.draw(
                    in: CGRect(x: metricsX, y: metricY, width: metricsWidth, height: 16),
                    withAttributes: [.font: language.uiFont(size: 9.5, weight: .medium), .foregroundColor: UIColor.label]
                )
                metricY += 18.0
            }
            cursorY += photoHeight + 14.0
            
            // Divider
            drawDivider(y: cursorY, width: contentWidth, marginX: marginX)
            cursorY += 12.0
            
            // 4. Modality 2: Hemodynamic Dual-Site PPG Waveform Analysis
            let section2Title = (language == .thai)
                ? "2. การวิเคราะห์คลื่นชีพจรสองตำแหน่ง (Cardiac Baseline vs. Distal Big Toe)"
                : "2. Dual-Site Pulse Wave Morphology (Cardiac Baseline vs. Distal Toe)"
            section2Title.draw(
                in: CGRect(x: marginX, y: cursorY, width: contentWidth, height: 18),
                withAttributes: sectionHeaderAttr
            )
            cursorY += 22.0
            
            // Finger vs Toe Waveform Visualizations side-by-side
            let waveBoxWidth = (contentWidth - 12.0) / 2.0
            let waveBoxHeight: CGFloat = 80.0
            
            // Finger waveform box
            let fingerTitle = (language == .thai) ? "ปลายนิ้วมือ (Cardiac Baseline)" : "Fingertip (Cardiac Baseline)"
            let fingerBox = CGRect(x: marginX, y: cursorY, width: waveBoxWidth, height: waveBoxHeight)
            drawWaveformGraph(samples: fingerWaveformSamples, in: fingerBox, title: fingerTitle, strokeColor: UIColor.systemBlue, language: language)
            
            // Toe waveform box
            let toeTitle = (language == .thai) ? "นิ้วหัวแม่เท้า (Distal Extremity)" : "Big Toe (Distal Extremity)"
            let toeBox = CGRect(x: marginX + waveBoxWidth + 12.0, y: cursorY, width: waveBoxWidth, height: waveBoxHeight)
            drawWaveformGraph(samples: toeWaveformSamples, in: toeBox, title: toeTitle, strokeColor: UIColor.systemTeal, language: language)
            cursorY += waveBoxHeight + 12.0
            
            // Hemodynamic metrics table
            let hemo = report.hemodynamicResult
            let hemoMetrics: [(String, String)]
            if language == .thai {
                hemoMetrics = [
                    ("เวลาชีพจรขึ้น (SRT):", "นิ้วมือ: \(Int(hemo.fingerMorphometry.meanSystolicRiseTimeMs)) ms   |   นิ้วเท้า: \(Int(hemo.toeMorphometry.meanSystolicRiseTimeMs)) ms (ล่าช้า: +\(Int(hemo.srtDelayMs)) ms)"),
                    ("ดัชนีชีพจรปลายเท้าเทียบมือ (PRT):", String(format: "%.2f (ปกติ > 0.50; ชีพจรหน่วง < 0.35)", hemo.amplitudeRatio)),
                    ("รอยหยัก Dicrotic Notch:", "นิ้วมือ: \(Int(hemo.fingerMorphometry.dicroticNotchPrevalence * 100))%   |   นิ้วเท้า: \(Int(hemo.toeMorphometry.dicroticNotchPrevalence * 100))% (สูญหาย: \(hemo.isToeDicroticNotchLost ? "ใช่" : "ไม่"))"),
                    ("ดัชนีคุณภาพสัญญาณ (SQI):", String(format: "นิ้วมือ: %.0f%%   |   นิ้วเท้า: %.0f%%", hemo.fingerMorphometry.signalQualityIndex * 100, hemo.toeMorphometry.signalQualityIndex * 100))
                ]
            } else {
                hemoMetrics = [
                    ("Systolic Rise Time (SRT):", "Finger: \(Int(hemo.fingerMorphometry.meanSystolicRiseTimeMs)) ms   |   Toe: \(Int(hemo.toeMorphometry.meanSystolicRiseTimeMs)) ms (Delay: +\(Int(hemo.srtDelayMs)) ms)"),
                    ("Toe-to-Finger Amplitude Ratio:", String(format: "%.2f (Normal > 0.50; Damped < 0.35)", hemo.amplitudeRatio)),
                    ("Dicrotic Notch Presence:", "Finger: \(Int(hemo.fingerMorphometry.dicroticNotchPrevalence * 100))%   |   Toe: \(Int(hemo.toeMorphometry.dicroticNotchPrevalence * 100))% (Loss: \(hemo.isToeDicroticNotchLost ? "YES" : "No"))"),
                    ("Signal Quality Index (SQI):", String(format: "Finger: %.0f%%   |   Toe: %.0f%%", hemo.fingerMorphometry.signalQualityIndex * 100, hemo.toeMorphometry.signalQualityIndex * 100))
                ]
            }
            
            for (label, val) in hemoMetrics {
                let line = "\(label)  \(val)"
                line.draw(
                    in: CGRect(x: marginX, y: cursorY, width: contentWidth, height: 14),
                    withAttributes: [.font: language.uiFont(size: 9.5, weight: .regular), .foregroundColor: UIColor.label]
                )
                cursorY += 15.0
            }
            cursorY += 10.0
            
            // Divider
            drawDivider(y: cursorY, width: contentWidth, marginX: marginX)
            cursorY += 12.0
            
            // 5. Clinical Impressions & Recommended Next Steps
            let section3Title = (language == .thai)
                ? "3. ผลการประเมินทางคลินิกและขั้นตอนแนะนำถัดไป"
                : "3. Clinical Evaluation & Recommended Next Steps"
            section3Title.draw(
                in: CGRect(x: marginX, y: cursorY, width: contentWidth, height: 18),
                withAttributes: sectionHeaderAttr
            )
            cursorY += 20.0
            
            for rec in report.recommendations {
                let localizedRec = HemosightStrings.localizeRecommendation(rec, language: language)
                let bullet = "• \(localizedRec)"
                bullet.draw(
                    in: CGRect(x: marginX + 8, y: cursorY, width: contentWidth - 16, height: 26),
                    withAttributes: [.font: language.uiFont(size: 9, weight: .medium), .foregroundColor: UIColor.darkGray]
                )
                cursorY += 20.0
            }
            
            // 6. Regulatory & Clinical Disclaimer Footer
            let footerRect = CGRect(x: marginX, y: pageHeight - 50.0, width: contentWidth, height: 35.0)
            let disclaimerStyle = NSMutableParagraphStyle()
            disclaimerStyle.alignment = .center
            if language == .thai {
                disclaimerStyle.lineSpacing = 2.0
            }
            let disclaimer = (language == .thai)
                ? "ข้อควรระวังทางการแพทย์: Hemosight เป็นเครื่องมือช่วยคัดกรองเบื้องต้น ไม่ใช่อุปกรณ์วินิจฉัยโรคตามการรับรองของ FDA และไม่สามารถใช้แทนการตรวจ Ankle-Brachial Index (ABI) หรืออัลตราซาวด์หลอดเลือด Doppler ได้ กรุณาปรึกษาแพทย์เฉพาะทางเพื่อรับการวินิจฉัยทางการแพทย์อย่างเป็นทางการ"
                : "CLINICAL DISCLAIMER: Hemosight is an investigational pre-screening tool designed for home screening. It is not an FDA-cleared diagnostic device and does not replace formal Doppler ultrasound or Ankle-Brachial Index (ABI) examination. Consult a qualified vascular specialist or physician."
            disclaimer.draw(
                in: footerRect,
                withAttributes: [
                    .font: language.uiFont(size: 7.5, weight: .regular),
                    .foregroundColor: UIColor.tertiaryLabel,
                    .paragraphStyle: disclaimerStyle
                ]
            )
        }
    }
    
    private func drawDivider(y: CGFloat, width: CGFloat, marginX: CGFloat) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: marginX, y: y))
        path.addLine(to: CGPoint(x: marginX + width, y: y))
        path.lineWidth = 0.5
        UIColor.systemGray4.setStroke()
        path.stroke()
    }
    
    private func drawWaveformGraph(samples: [Float], in rect: CGRect, title: String, strokeColor: UIColor, language: AppLanguage) {
        // Draw background container
        let bgPath = UIBezierPath(roundedRect: rect, cornerRadius: 4)
        UIColor.systemGray6.setFill()
        bgPath.fill()
        UIColor.systemGray4.setStroke()
        bgPath.lineWidth = 0.5
        bgPath.stroke()
        
        // Title label
        title.draw(
            in: CGRect(x: rect.origin.x + 6, y: rect.origin.y + 4, width: rect.width - 12, height: 12),
            withAttributes: [.font: language.uiFont(size: 8, weight: .semibold), .foregroundColor: UIColor.darkGray]
        )
        
        guard samples.count > 10 else { return }
        
        let graphY = rect.origin.y + 18.0
        let graphHeight = rect.height - 24.0
        let graphWidth = rect.width - 12.0
        let graphX = rect.origin.x + 6.0
        
        // Slice a representative 3-second segment (180 samples)
        let sampleWindow = Array(samples.suffix(180))
        guard let minVal = sampleWindow.min(), let maxVal = sampleWindow.max(), maxVal > minVal else { return }
        let range = maxVal - minVal
        
        let path = UIBezierPath()
        let stepX = graphWidth / CGFloat(sampleWindow.count - 1)
        
        for (i, val) in sampleWindow.enumerated() {
            let normalized = CGFloat((val - minVal) / range)
            let x = graphX + (CGFloat(i) * stepX)
            let y = graphY + graphHeight - (normalized * graphHeight)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        strokeColor.setStroke()
        path.lineWidth = 1.2
        path.stroke()
    }
}

// MARK: - Test Double (SpyingStub)

#if DEBUG
@MainActor
public final class ReportGenerationServiceSpyingStub: ReportGenerationServiceProtocol, @unchecked Sendable {
    public private(set) var generatedReports: [ComprehensivePADReport] = []
    public private(set) var capturedFootImages: [UIImage?] = []
    public private(set) var usedLanguages: [AppLanguage] = []
    public var dataToReturn: Data
    
    public init(dataToReturn: Data = Data([0x25, 0x50, 0x44, 0x46])) { // %PDF header
        self.dataToReturn = dataToReturn
    }
    
    public func generatePDFReport(
        report: ComprehensivePADReport,
        footImage: UIImage?,
        fingerWaveformSamples: [Float],
        toeWaveformSamples: [Float],
        language: AppLanguage = .english
    ) -> Data {
        generatedReports.append(report)
        capturedFootImages.append(footImage)
        usedLanguages.append(language)
        return dataToReturn
    }
}
#endif
