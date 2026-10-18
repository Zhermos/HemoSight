import Foundation

/// Centralized, type-safe clinical localization strings for Hemosight.
public enum HemosightStrings {
    
    // MARK: - App & Navigation
    
    public static func appTitle(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Hemosight"
        case .thai: return "Hemosight | ระบบคัดกรองหลอดเลือด"
        }
    }
    
    public static func reset(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Reset"
        case .thai: return "เริ่มใหม่"
        }
    }
    
    public static func resetAccessibilityHint(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Reset screening workflow"
        case .thai: return "เริ่มขั้นตอนการตรวจใหม่ทั้งหมด"
        }
    }
    
    public static func languageToggleAccessibilityLabel(current: AppLanguage) -> String {
        switch current {
        case .english: return "Change language. Currently English."
        case .thai: return "เปลี่ยนภาษา ปัจจุบันคือภาษาไทย"
        }
    }
    
    // MARK: - Workflow Stepper
    
    public static func stepperShortName(for step: ScreeningStep, language: AppLanguage) -> String {
        switch language {
        case .english:
            switch step {
            case .step1VisualPhoto: return "Foot Photo"
            case .step2FingerPPG: return "Finger Pulse"
            case .step3ToePPG: return "Toe Pulse"
            case .step4Dashboard: return "Results"
            }
        case .thai:
            switch step {
            case .step1VisualPhoto: return "ภาพหลังเท้า"
            case .step2FingerPPG: return "ชีพจรนิ้วมือ"
            case .step3ToePPG: return "ชีพจรนิ้วเท้า"
            case .step4Dashboard: return "ผลประเมิน"
            }
        }
    }
    
    public static func stepperFullTitle(for step: ScreeningStep, language: AppLanguage) -> String {
        switch language {
        case .english:
            switch step {
            case .step1VisualPhoto: return "Step 1: Bilateral Foot Photo"
            case .step2FingerPPG: return "Step 2: Fingertip Pulse (Baseline)"
            case .step3ToePPG: return "Step 3: Big Toe Pulse (Distal)"
            case .step4Dashboard: return "Step 4: Clinical Risk Assessment"
            }
        case .thai:
            switch step {
            case .step1VisualPhoto: return "ขั้นตอนที่ 1: ถ่ายภาพหลังเท้าทั้งสองข้าง"
            case .step2FingerPPG: return "ขั้นตอนที่ 2: ตรวจชีพจรปลายนิ้วมือ"
            case .step3ToePPG: return "ขั้นตอนที่ 3: ตรวจชีพจรนิ้วหัวแม่เท้า"
            case .step4Dashboard: return "ขั้นตอนที่ 4: สรุปผลการประเมินความเสี่ยง"
            }
        }
    }
    
    public static func stepperProgressAccessibility(step: ScreeningStep, current: ScreeningStep, total: Int, language: AppLanguage) -> String {
        switch language {
        case .english:
            let status = step.rawValue < current.rawValue ? "Completed" : (step == current ? "Current step" : "Upcoming")
            return "Step \(step.rawValue): \(stepperShortName(for: step, language: .english)), \(status)"
        case .thai:
            let status = step.rawValue < current.rawValue ? "เสร็จสิ้นแล้ว" : (step == current ? "ขั้นตอนปัจจุบัน" : "ขั้นตอนถัดไป")
            return "ขั้นตอนที่ \(step.rawValue): \(stepperShortName(for: step, language: .thai)), \(status)"
        }
    }
    
    // MARK: - Step 1: Visual Foot Photo
    
    public static func visualInspectionTitle(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Bilateral Dorsal Foot Inspection"
        case .thai: return "การตรวจความสมมาตรของหลังเท้าทั้งสองข้าง"
        }
    }
    
    public static func visualInspectionDescription(for language: AppLanguage) -> String {
        switch language {
        case .english:
            return "Position both feet side-by-side under clear, even lighting. Our computer vision engine analyzes skin color symmetry (CIE L*a*b*) to detect unilateral blanching or ischemic pallor."
        case .thai:
            return "วางเท้าทั้งสองข้างชิดกันในบริเวณที่มีแสงสว่างชัดเจนและสม่ำเสมอ ระบบประมวลผลภาพจะวิเคราะห์ความสมมาตรของสีผิว (CIE L*a*b*) เพื่อตรวจหาภาวะซีดขาวหรือการขาดเลือดเฉพาะข้าง"
        }
    }
    
    public static func visualPlacementTitle(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Align Left and Right Feet Here"
        case .thai: return "จัดตำแหน่งเท้าซ้ายและขวาให้อยู่ในกรอบนี้"
        }
    }
    
    public static func visualPlacementSubtitle(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Ensure dorsal skin (top of feet) is fully uncovered"
        case .thai: return "กรุณาเปิดผิวบริเวณหลังเท้าให้มองเห็นได้ชัดเจน"
        }
    }
    
    public static func visualAnalyzing(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Analyzing bilateral chromaticity..."
        case .thai: return "กำลังวิเคราะห์ความสมดุลของสีผิวและภาวะซีด..."
        }
    }
    
    public static func visualPickButton(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Select Foot Photo from Library"
        case .thai: return "เลือกภาพถ่ายหลังเท้าจากคลังภาพ"
        }
    }
    
    public static func visualPickButtonHint(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Opens photo library to pick dorsal foot inspection image"
        case .thai: return "เปิดคลังภาพเพื่อเลือกรูปถ่ายหลังเท้าสำหรับประเมิน"
        }
    }
    
    public static func visualLoadError(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Failed to load selected photo."
        case .thai: return "ไม่สามารถเปิดไฟล์รูปภาพที่เลือกได้"
        }
    }
    
    // MARK: - Steps 2 & 3: PPG Scan & Guidance
    
    public static func ppgSiteTitle(for site: PPGSite, language: AppLanguage) -> String {
        switch language {
        case .english:
            return site.rawValue
        case .thai:
            switch site {
            case .finger: return "ชีพจรปลายนิ้วมือ (ค่าอ้างอิงหัวใจ)"
            case .toe: return "ชีพจรนิ้วหัวแม่เท้า (หลอดเลือดส่วนปลาย)"
            }
        }
    }
    
    public static func ppgInstruction(for site: PPGSite, language: AppLanguage) -> String {
        switch language {
        case .english:
            switch site {
            case .finger: return "Place your index fingertip gently over the rear camera lens and flash."
            case .toe: return "Rest your big toe gently over the rear camera lens and flash while seated comfortably."
            }
        case .thai:
            switch site {
            case .finger: return "วางปลายนิ้วชี้เบาๆ บนเลนส์กล้องหลังและไฟแฟลช"
            case .toe: return "นั่งในท่าที่สบาย แล้ววางนิ้วหัวแม่เท้าเบาๆ บนเลนส์กล้องหลังและไฟแฟลช"
            }
        }
    }
    
    public static func contactQuality(for state: CameraContactState, language: AppLanguage) -> String {
        switch language {
        case .english:
            return state.rawValue
        case .thai:
            switch state {
            case .optimal:
                return "คุณภาพสัญญาณดีเยี่ยม — กรุณาวางนิ่งๆ"
            case .notCovered:
                return "กรุณาวางปลายนิ้ว/นิ้วเท้าให้ปิดเลนส์กล้องและแฟลชให้สนิท"
            case .tooLight:
                return "ตรวจพบแสงรั่ว — กรุณาแนบนิ้วให้สนิทกับเลนส์"
            case .overPressed:
                return "กดแรงเกินไป — กรุณาผ่อนแรงกดเล็กน้อยเพื่อไม่ให้หลอดเลือดตีบ"
            }
        }
    }
    
    public static func livePPGChartTitle(for language: AppLanguage) -> String {
        switch language {
        case .english: return "LIVE PHOTOPLETHYSMOGRAM (PPG)"
        case .thai: return "สัญญาณคลื่นชีพจรแบบเรียลไทม์ (PPG)"
        }
    }
    
    public static func secondsRemainingLabel(for language: AppLanguage) -> String {
        switch language {
        case .english: return "SECONDS REMAINING"
        case .thai: return "วินาทีที่เหลือ"
        }
    }
    
    public static func startScanButton(site: PPGSite, language: AppLanguage) -> String {
        switch language {
        case .english:
            return "Start 30s \(site == .finger ? "Finger" : "Toe") Scan"
        case .thai:
            return "เริ่มสแกน\(site == .finger ? "นิ้วมือ" : "นิ้วเท้า") 30 วินาที"
        }
    }
    
    public static func cancelScanButton(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Cancel Scan"
        case .thai: return "ยกเลิกการสแกน"
        }
    }
    
    // MARK: - Step 4: Clinical Results Dashboard
    
    public static func riskTierTitle(for level: PADRiskLevel, language: AppLanguage) -> String {
        switch language {
        case .english:
            return level.rawValue
        case .thai:
            switch level {
            case .low: return "ความเสี่ยงต่ำ (Low Risk)"
            case .moderate: return "ความเสี่ยงปานกลาง (Borderline)"
            case .high: return "ความเสี่ยงสูง (High Risk / Ischemia)"
            }
        }
    }
    
    public static func riskScoreTitle(score: Int, language: AppLanguage) -> String {
        switch language {
        case .english: return "Vascular Risk Score: \(score) / 100"
        case .thai: return "คะแนนความเสี่ยงโรคหลอดเลือด: \(score) / 100"
        }
    }
    
    public static func clinicalSummary(for level: PADRiskLevel, language: AppLanguage) -> String {
        switch language {
        case .english:
            return level.clinicalSummary
        case .thai:
            switch level {
            case .low:
                return "ความสมมาตรของเท้าทั้งสองข้างปกติและคลื่นชีพจรที่นิ้วหัวแม่เท้ามีความชัดเจน"
            case .moderate:
                return "ตรวจพบชีพจรส่วนปลายหน่วงเล็กน้อยหรือสีผิวไม่สมมาตร แนะนำตรวจซ้ำใน 14 วัน"
            case .high:
                return "ตรวจพบการหน่วงของชีพจรอย่างมีนัยสำคัญหรือมีอาการซีดอย่างชัดเจน แนะนำพบแพทย์เพื่อตรวจ ABI และอัลตราซาวด์หลอดเลือดทันที"
            }
        }
    }
    
    public static func metricsSectionTitle(for language: AppLanguage) -> String {
        switch language {
        case .english: return "VASCULAR SCREENING METRICS"
        case .thai: return "ค่าตัวชี้วัดการไหลเวียนเลือดและผิวหนัง"
        }
    }
    
    // Metric 1: Skin Color Disparity
    public static func metricColorDisparityLabel(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Bilateral Skin Color Disparity (ΔE)"
        case .thai: return "ความไม่สมมาตรของสีผิวเท้า (Color Disparity)"
        }
    }
    
    public static func metricColorDisparityStatus(isWarning: Bool, language: AppLanguage) -> String {
        switch language {
        case .english: return isWarning ? "Disparity Flagged" : "Normal"
        case .thai: return isWarning ? "พบความไม่สมมาตร (Disparity Flagged)" : "ปกติ (Normal)"
        }
    }
    
    // Metric 2: Toe Systolic Rise Time
    public static func metricSRTLabel(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Toe Systolic Rise Time (SRT)"
        case .thai: return "เวลาเพิ่มขึ้นของคลื่นชีพจรนิ้วเท้า (SRT)"
        }
    }
    
    public static func metricSRTStatus(isWarning: Bool, language: AppLanguage) -> String {
        switch language {
        case .english: return isWarning ? "Prolonged / Damped" : "Crisp Upstroke"
        case .thai: return isWarning ? "คลื่นชีพจรหน่วง / ช้าลง (Prolonged / Damped)" : "คลื่นชีพจรคมชัด (Crisp Upstroke)"
        }
    }
    
    // Metric 3: Toe-to-Finger Amplitude Ratio
    public static func metricAmplitudeRatioLabel(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Toe-to-Finger Amplitude Ratio"
        case .thai: return "ดัชนีชีพจรปลายเท้าเทียบมือ (PRT Ratio)"
        }
    }
    
    public static func metricAmplitudeRatioStatus(isWarning: Bool, language: AppLanguage) -> String {
        switch language {
        case .english: return isWarning ? "Diminished" : "Robust Perfusion"
        case .thai: return isWarning ? "การไหลเวียนลดลง (Diminished)" : "การไหลเวียนเลือดดีเยี่ยม (Robust Perfusion)"
        }
    }
    
    // Metric 4: Lightness Disparity
    public static func metricLightnessDisparityLabel(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Skin Lightness Disparity (ΔL*)"
        case .thai: return "ระดับความซีด (Lightness Disparity)"
        }
    }
    
    // Next steps
    public static func recommendationsHeader(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Next Steps & Recommendations"
        case .thai: return "คำแนะนำทางการแพทย์และขั้นตอนถัดไป"
        }
    }
    
    public static func sharePDFButton(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Share Clinical PDF to Doctor"
        case .thai: return "แชร์รายงาน PDF ทางการแพทย์ให้แพทย์"
        }
    }
    
    public static func synthesizingReport(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Synthesizing clinical findings..."
        case .thai: return "กำลังประมวลผลและสรุปผลตรวจทางการแพทย์..."
        }
    }
    
    /// Translates clinical recommendations into Thai if applicable, or preserves original if English.
    public static func localizeRecommendation(_ text: String, language: AppLanguage) -> String {
        guard language == .thai else { return text }
        
        if text.contains("Schedule in-person clinical evaluation for formal Ankle-Brachial Index") || text.contains("URGENT") {
            return "ด่วน: แนะนำให้ปรึกษาแพทย์เฉพาะทางด้านโรคหลอดเลือดและหัวใจเพื่อรับการตรวจ ABI และอัลตราซาวด์หลอดเลือดโดยเร็ว"
        }
        if text.contains("Repeat Hemosight screening in 14 days") || text.contains("RECOMMENDED") {
            return "แนะนำ: ตรวจคัดกรองซ้ำใน 14 วัน และเฝ้าระวังอาการปวดเมื่อยน่องขณะเดิน (Claudication)"
        }
        if text.contains("Normal bilateral perfusion findings") {
            return "ผลการตรวจการไหลเวียนเลือดปกติ ควรดูแลสุขภาพหัวใจ หลอดเลือด และสุขอนามัยของผิวเท้าอย่างต่อเนื่อง"
        }
        if text.contains("Severe pulse upstroke delay detected at toe") {
            return "ตรวจพบคลื่นชีพจรนิ้วเท้าขึ้นช้ากว่าปกติอย่างมาก เข้าข่ายภาวะหลอดเลือดแดงส่วนต้นตีบตัน"
        }
        if text.contains("Prolonged toe systolic rise time") {
            return "เวลาคลื่นชีพจรนิ้วเท้าขึ้นนานผิดปกติ บ่งชี้ถึงแรงดันชีพจรส่วนปลายที่ลดทอนลง"
        }
        if text.contains("Marked attenuation of distal microcirculatory pulse volume") {
            return "ปริมาตรคลื่นชีพจรที่หลอดเลือดฝอยส่วนปลายลดลงอย่างชัดเจน"
        }
        if text.contains("Diminished pulse amplitude ratio") {
            return "อัตราส่วนความสูงของคลื่นชีพจรนิ้วเท้าต่อนิ้วมือลดต่ำกว่าเกณฑ์ปกติ"
        }
        if text.contains("Blunted toe waveform with complete disappearance of the dicrotic wave notch") {
            return "คลื่นชีพจรนิ้วเท้าทู่ลงและไม่พบรอยหยัก Dicrotic Notch ซึ่งสัมพันธ์กับความยืดหยุ่นหลอดเลือดที่ลดลง"
        }
        if text.contains("Pronounced bilateral cutaneous chromatic discrepancy") {
            return "สีผิวของหลังเท้าทั้งสองข้างมีความแตกต่างกันอย่างมีนัยสำคัญทางคลินิก"
        }
        if text.contains("Unilateral dorsal foot blanching") {
            return "ตรวจพบภาวะผิวหนังหลังเท้าซีดขาวเฉพาะข้าง"
        }
        
        return text
    }
}
