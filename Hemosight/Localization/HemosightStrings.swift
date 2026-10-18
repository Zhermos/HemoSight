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
        case .thai: return "รีเซ็ต"
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
    
    // MARK: - Step Completion & Navigation
    
    public static func backButton(for language: AppLanguage) -> String {
        language == .thai ? "ย้อนกลับ" : "Back"
    }
    
    public static func retestButton(for language: AppLanguage) -> String {
        language == .thai ? "วัดซ้ำ (ทำใหม่)" : "Retest / Scan Again"
    }
    
    public static func proceedToNextStepButton(for step: ScreeningStep, language: AppLanguage) -> String {
        switch step {
        case .step1FingerPPG:
            return language == .thai ? "บันทึกและไปตรวจนิ้วเท้าถัดไป" : "Save & Proceed to Toe Pulse"
        case .step2ToePPG:
            return language == .thai ? "บันทึกและดูผลการประเมิน" : "Save & View Clinical Results"
        case .step3Dashboard:
            return language == .thai ? "เสร็จสิ้น" : "Done"
        }
    }
    
    public static func scanCompletedTitle(for site: PPGSite, language: AppLanguage) -> String {
        language == .thai 
            ? "บันทึกสัญญาณชีพจรเรียบร้อยแล้ว" 
            : "Pulse Signal Recorded Successfully"
    }
    
    public static func scanCompletedSubtitle(for language: AppLanguage) -> String {
        language == .thai 
            ? "ตรวจสอบสัญญาณด้านบน หากคลื่นชีพจรชัดเจนให้กดไปขั้นตอนถัดไป หรือกดวัดซ้ำหากต้องการบันทึกใหม่" 
            : "Review waveform above. Tap proceed if clear, or retest if you need to record again."
    }
    
    // MARK: - Workflow Stepper
    
    public static func stepperShortName(for step: ScreeningStep, language: AppLanguage) -> String {
        switch language {
        case .english:
            switch step {
            case .step1FingerPPG: return "Finger Pulse"
            case .step2ToePPG: return "Toe Pulse"
            case .step3Dashboard: return "Results"
            }
        case .thai:
            switch step {
            case .step1FingerPPG: return "ชีพจรนิ้วมือ"
            case .step2ToePPG: return "ชีพจรนิ้วเท้า"
            case .step3Dashboard: return "ผลตรวจสรุป"
            }
        }
    }
    
    public static func stepperFullTitle(for step: ScreeningStep, language: AppLanguage) -> String {
        switch language {
        case .english:
            switch step {
            case .step1FingerPPG: return "Step 1: Fingertip Pulse (Baseline)"
            case .step2ToePPG: return "Step 2: Big Toe Pulse (Distal)"
            case .step3Dashboard: return "Step 3: Clinical Results Dashboard"
            }
        case .thai:
            switch step {
            case .step1FingerPPG: return "ขั้นตอนที่ 1: ตรวจชีพจรปลายนิ้วมือ"
            case .step2ToePPG: return "ขั้นตอนที่ 2: ตรวจชีพจรนิ้วหัวแม่เท้า"
            case .step3Dashboard: return "ขั้นตอนที่ 3: สรุปผลการตรวจคัดกรอง"
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
    
    public static func visualCameraButton(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Take Photo with Camera"
        case .thai: return "ถ่ายภาพด้วยกล้อง"
        }
    }
    
    public static func visualLibraryButton(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Choose from Library"
        case .thai: return "เลือกจากอัลบั้มภาพ"
        }
    }
    
    public static func cameraUnavailableError(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Camera is not available on this device."
        case .thai: return "ไม่สามารถเปิดกล้องถ่ายภาพได้บนอุปกรณ์นี้"
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
    
    public static func pulseRateCardTitle(for language: AppLanguage) -> String {
        switch language {
        case .english: return "REAL-TIME PULSE RATE"
        case .thai: return "อัตราการเต้นของชีพจร"
        }
    }
    
    public static func pulseRateUnit(for language: AppLanguage) -> String {
        switch language {
        case .english: return "BPM"
        case .thai: return "ครั้ง/นาที"
        }
    }
    
    public static func pulseRateCalculating(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Measuring..."
        case .thai: return "กำลังวัดค่า..."
        }
    }
    
    public static func pulseRateAccessibilityLabel(bpm: Int?, language: AppLanguage) -> String {
        switch language {
        case .english:
            if let bpm = bpm {
                return "Pulse rate: \(bpm) beats per minute"
            } else {
                return "Pulse rate: measuring"
            }
        case .thai:
            if let bpm = bpm {
                return "อัตราชีพจร: \(bpm) ครั้งต่อนาที"
            } else {
                return "อัตราชีพจร: กำลังวัดค่า"
            }
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
    
    // MARK: - Motion Artifact Detection
    
    public static func motionWarningLabel(for language: AppLanguage) -> String {
        language == .thai ? "ตรวจพบการเคลื่อนไหว — กรุณาอยู่นิ่งๆ" : "Motion Detected — Please Keep Still"
    }
    
    public static func motionExcessiveNotice(for language: AppLanguage) -> String {
        language == .thai 
            ? "มีการขยับตัวบ่อยระหว่างตรวจ แนะนำให้กดวัดซ้ำเพื่อให้ผลตรวจแม่นยำที่สุด" 
            : "Frequent motion detected during scan. Retesting is recommended for clinical accuracy."
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
    
    // MARK: - Supplemental Foot Photo Inspection (Optional in Results)
    
    public static func supplementalFootScanButton(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Perform Foot Photo Inspection (Optional for Higher Accuracy)"
        case .thai: return "ตรวจวิเคราะห์ภาพถ่ายเท้าเพิ่มเติม (เพื่อความแม่นยำสูงสุด)"
        }
    }
    
    public static func supplementalFootScanCompleted(deltaE: Double, language: AppLanguage) -> String {
        switch language {
        case .english: return String(format: "Foot Photo Analyzed (Color Disparity: ΔE %.1f)", deltaE)
        case .thai: return String(format: "ตรวจวิเคราะห์ภาพเท้าแล้ว (ความแตกต่างสีผิว: ΔE %.1f)", deltaE)
        }
    }
    
    public static func supplementalFootScanRetake(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Retake Foot Photo"
        case .thai: return "ถ่ายภาพเท้าใหม่"
        }
    }
    
    public static func supplementalFootScanHeader(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Supplemental Foot Skin & Visual Inspection"
        case .thai: return "การตรวจสภาพผิวหนังและสีเท้าเพิ่มเติม"
        }
    }
    
    public static func supplementalFootScanPrompt(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Bilateral dorsal foot photography helps detect localized ischemia and refines screening accuracy."
        case .thai: return "การตรวจภาพถ่ายหลังเท้าทั้งสองข้างช่วยตรวจจับภาวะขาดเลือดเฉพาะส่วน (Ischemia) และเพิ่มความแม่นยำในการคัดกรอง"
        }
    }
    
    public static func supplementalFootScanTutorialLink(for language: AppLanguage) -> String {
        switch language {
        case .english: return "How to take foot photos properly (?)"
        case .thai: return "ดูวิธีถ่ายภาพเท้าที่ถูกต้อง (?)"
        }
    }
    
    // MARK: - Contextual Step-by-Step Tutorial Flow
    
    public static func helpButtonAccessibilityLabel(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Tutorial guide for this step"
        case .thai: return "คำแนะนำการตรวจของขั้นตอนนี้"
        }
    }
    
    public static func tutorialCloseButton(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Close"
        case .thai: return "ปิด"
        }
    }
    
    public static func dontShowAgainForStepCheckbox(for language: AppLanguage) -> String {
        switch language {
        case .english: return "Don't show tutorial again for this step"
        case .thai: return "ไม่ต้องแสดงคำแนะนำของขั้นตอนนี้อีก"
        }
    }
    
    public static func stepTutorialChecklistHeader(for language: AppLanguage) -> String {
        switch language {
        case .english: return "3 Key Clinical Instructions"
        case .thai: return "ข้อปฏิบัติสำคัญ 3 ประการ"
        }
    }
    
    public static func stepTutorialTitle(for step: ScreeningStep, language: AppLanguage) -> String {
        switch step {
        case .step1FingerPPG:
            return language == .thai ? "วิธีวางนิ้วมือตรวจคลื่นชีพจร" : "How to Position Fingertip for Pulse"
        case .step2ToePPG:
            return language == .thai ? "วิธีวางนิ้วหัวแม่เท้าตรวจคลื่นชีพจร" : "How to Position Big Toe for Pulse"
        case .step3Dashboard:
            return language == .thai ? "สรุปผลการประเมินทางการแพทย์" : "Clinical Risk Assessment Summary"
        }
    }
    
    public static func footPhotoTutorialTitle(for language: AppLanguage) -> String {
        language == .thai ? "วิธีถ่ายภาพหลังเท้าทั้งสองข้าง" : "How to Take Bilateral Foot Photos"
    }
    
    public static func stepTutorialSubtitle(for step: ScreeningStep, language: AppLanguage) -> String {
        switch step {
        case .step1FingerPPG:
            return language == .thai ? "ขั้นตอนที่ 1: ชีพจรนิ้วมือ (ค่าอ้างอิงหัวใจ)" : "Step 1: Fingertip Cardiac Baseline"
        case .step2ToePPG:
            return language == .thai ? "ขั้นตอนที่ 2: ชีพจรนิ้วเท้า (หลอดเลือดส่วนปลาย)" : "Step 2: Big Toe Distal Perfusion"
        case .step3Dashboard:
            return language == .thai ? "ขั้นตอนที่ 3: สรุปผลการประเมิน" : "Step 3: Clinical Risk Assessment"
        }
    }
    
    public static func footPhotoTutorialSubtitle(for language: AppLanguage) -> String {
        language == .thai ? "การตรวจภาพถ่ายสีผิวและความสมมาตร" : "Visual Inspection & Saliency"
    }
    
    public static func footPhotoTutorialChecklist(for language: AppLanguage) -> [String] {
        if language == .thai {
            return [
                "วางเท้าเปล่าทั้งสองข้างขนานกันบนพื้นราบ",
                "ถอดถุงเท้าและดึงขากางเกงขึ้น ในบริเวณที่มีแสงสว่างชัดเจน",
                "ถือโทรศัพท์ด้วยสองมือ ให้เท้าทั้งสองข้างอยู่ในกรอบภาพสีเขียว"
            ]
        } else {
            return [
                "Place both bare feet parallel and flat on the ground",
                "Remove socks and pull up pant legs under clear, even lighting",
                "Hold phone with both hands, framing both feet inside the green guide box"
            ]
        }
    }
    
    public static func stepTutorialChecklist(for step: ScreeningStep, language: AppLanguage) -> [String] {
        switch step {
        case .step1FingerPPG:
            if language == .thai {
                return [
                    "ใช้นิ้วชี้มือข้างที่ถนัดวางบนเลนส์กล้องหลัง",
                    "ให้เนื้อปลายนิ้วปิดเลนส์มิดชิด และขอบนิ้วสัมผัสแสงไฟแฟลช",
                    "แตะเบาๆ ไม่กดแน่น อยู่นิ่งๆ ตลอดเวลา 30 วินาที"
                ]
            } else {
                return [
                    "Place index fingertip of dominant hand over the rear camera lens",
                    "Ensure fingertip completely seals the lens and touches the LED flash",
                    "Touch gently without pressing hard, and hold still for 30 seconds"
                ]
            }
        case .step2ToePPG:
            if language == .thai {
                return [
                    "นั่งบนเก้าอี้ที่มั่นคงในท่าที่สบายและผ่อนคลาย",
                    "วางโทรศัพท์บนพื้นหรือม้านั่งเตี้ย แล้ววางนิ้วโป้งเท้าปิดเลนส์กล้องและแฟลช",
                    "วางนิ่งๆ ไม่เกร็งเท้า อยู่นิ่งๆ ตลอด 30 วินาที"
                ]
            } else {
                return [
                    "Sit comfortably and relaxed on a sturdy chair",
                    "Place phone on floor or low stool, resting your big toe over lens and flash",
                    "Keep foot relaxed without clenching, holding still for 30 seconds"
                ]
            }
        case .step3Dashboard:
            if language == .thai {
                return [
                    "ตรวจสอบระดับความเสี่ยง (เขียว/เหลือง/แดง) และคะแนน PAD Risk Score",
                    "อ่านคำแนะนำทางการแพทย์และข้อสังเกตความแตกต่างของคลื่นชีพจร",
                    "กดปุ่ม 'แชร์รายงาน PDF' เพื่อส่งผลตรวจอย่างเป็นทางการให้แพทย์ผู้เชี่ยวชาญ"
                ]
            } else {
                return [
                    "Review risk level (Low/Moderate/High) and composite PAD Risk Score",
                    "Examine clinical observations and bilateral pulse wave disparities",
                    "Tap 'Share Clinical PDF' to export formal report to your healthcare provider"
                ]
            }
        }
    }
    
    public static func stepTutorialActionButton(for step: ScreeningStep, language: AppLanguage) -> String {
        switch step {
        case .step1FingerPPG:
            return language == .thai ? "เข้าใจแล้ว เริ่มตรวจชีพจรนิ้วมือ" : "Understood, Start Finger Pulse"
        case .step2ToePPG:
            return language == .thai ? "เข้าใจแล้ว เริ่มตรวจชีพจรนิ้วเท้า" : "Understood, Start Toe Pulse"
        case .step3Dashboard:
            return language == .thai ? "เข้าใจแล้ว ดูผลการประเมิน" : "Understood, View Results"
        }
    }
    
    // MARK: - Legacy TutorialSheetView Compatibility
    
    public static func tutorialTitle(for language: AppLanguage) -> String {
        language == .thai ? "คำแนะนำการตรวจหลอดเลือด" : "Vascular Screening Instructions"
    }
    
    public static func dontShowAgainCheckbox(for language: AppLanguage) -> String {
        dontShowAgainForStepCheckbox(for: language)
    }
    
    // Step 1
    public static func tutorialStep1Title(for language: AppLanguage) -> String {
        footPhotoTutorialTitle(for: language)
    }
    public static func tutorialStep1Subtitle(for language: AppLanguage) -> String {
        footPhotoTutorialSubtitle(for: language)
    }
    public static func tutorialStep1Rule(for language: AppLanguage) -> String {
        language == .thai 
            ? "ถอดถุงเท้า วางเท้าคู่ขนานบนพื้นราบ ถือโทรศัพท์ด้วย 2 มือเล็งในกรอบสีเขียว" 
            : "Remove socks, place both feet parallel on flat floor, and frame in green box with both hands."
    }
    
    // Step 2
    public static func tutorialStep2Title(for language: AppLanguage) -> String {
        stepTutorialTitle(for: .step1FingerPPG, language: language)
    }
    public static func tutorialStep2Subtitle(for language: AppLanguage) -> String {
        stepTutorialSubtitle(for: .step1FingerPPG, language: language)
    }
    public static func tutorialStep2Rule(for language: AppLanguage) -> String {
        language == .thai 
            ? "วางปลายนิ้วชี้แตะเบาๆ ปิดเลนส์กล้องหลังและไฟแฟลช อยู่นิ่งๆ 30 วินาที" 
            : "Gently place index fingertip covering rear camera and flash, holding still for 30 seconds."
    }
    
    // Step 3
    public static func tutorialStep3Title(for language: AppLanguage) -> String {
        stepTutorialTitle(for: .step2ToePPG, language: language)
    }
    public static func tutorialStep3Subtitle(for language: AppLanguage) -> String {
        stepTutorialSubtitle(for: .step2ToePPG, language: language)
    }
    public static func tutorialStep3Rule(for language: AppLanguage) -> String {
        language == .thai 
            ? "นั่งท่าสบาย วางเท้าราบบนแท่นหรือเก้าอี้เตี้ย นำนิ้วหัวแม่เท้าแตะกล้องหลังและแฟลช นิ่ง 30 วินาที" 
            : "Sit comfortably with foot resting flat on a low stool, big toe over camera and flash for 30s."
    }
    
    // Step 4
    public static func tutorialStep4Title(for language: AppLanguage) -> String {
        stepTutorialTitle(for: .step3Dashboard, language: language)
    }
    public static func tutorialStep4Subtitle(for language: AppLanguage) -> String {
        stepTutorialSubtitle(for: .step3Dashboard, language: language)
    }
    public static func tutorialStep4Rule(for language: AppLanguage) -> String {
        language == .thai 
            ? "ตรวจสอบผลการประเมินความเสี่ยงและส่งออกรายงานสรุปสำหรับแพทย์" 
            : "Review clinical risk evaluation and export clinical summary report."
    }
    
    public static func nextButton(for language: AppLanguage) -> String {
        language == .thai ? "ถัดไป" : "Next"
    }
    
    public static func startScreeningButton(for language: AppLanguage) -> String {
        language == .thai ? "เริ่มการตรวจ" : "Start Screening"
    }
}
