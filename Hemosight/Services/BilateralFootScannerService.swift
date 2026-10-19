import Foundation
import UIKit
import Vision
import CoreImage

/// Errors that can occur during bilateral dorsal foot visual analysis.
public enum VisualInspectionError: LocalizedError {
    case invalidImageData
    case feetSegmentationFailed
    case insufficientContoursDetected
    case illuminationInadequate
    case noHumanSkinDetected
    
    public var errorDescription: String? {
        let isThai = UserDefaults.standard.string(forKey: "app_language") == "th"
        switch self {
        case .invalidImageData:
            return isThai ? "ไม่สามารถประมวลผลไฟล์ภาพที่เลือกได้" : "Unable to process the captured photo format."
        case .feetSegmentationFailed:
            return isThai ? "ไม่สามารถแยกตำแหน่งเท้าซ้ายและขวาได้ชัดเจน กรุณาวางเท้าทั้งสองข้างให้อยู่ในกรอบ" : "Could not delineate left and right foot boundaries. Please ensure both feet are clearly positioned within the guide silhouette."
        case .insufficientContoursDetected:
            return isThai ? "ตรวจพบพื้นที่ผิวหนังไม่เพียงพอสำหรับการวิเคราะห์" : "Insufficient dorsal skin surface detected for bilateral analysis."
        case .illuminationInadequate:
            return isThai ? "สภาพแสงมืดหรือสลัวเกินไป กรุณาถ่ายภาพในบริเวณที่มีแสงสว่างเพียงพอ" : "Lighting is too dark or uneven. Please reposition with good ambient lighting."
        case .noHumanSkinDetected:
            return isThai ? "ไม่พบเท้าหรือสีผิวหนังมนุษย์ในภาพ กรุณาถ่ายภาพหลังเท้าเปล่าทั้งสองข้างให้เห็นชัดเจน" : "No human feet or skin tone detected in the photo. Please place both bare feet side-by-side in good lighting and capture again."
        }
    }
}

/// Protocol abstracting bilateral foot visual analysis for dependency injection and testability.
public protocol BilateralFootScannerServiceProtocol: Sendable {
    func analyzeBilateralDorsalFeet(image: UIImage) async throws -> VisualIschemiaResult
}

/// Service performing bilateral dorsal foot segmentation, CIE L*a*b* conversion, and color disparity analysis.
public final class BilateralFootScannerService: BilateralFootScannerServiceProtocol, @unchecked Sendable {
    
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private let yoloDetector: any YOLOFootDetectorServiceProtocol
    
    public init(yoloDetector: (any YOLOFootDetectorServiceProtocol)? = nil) {
        self.yoloDetector = yoloDetector ?? YOLOFootDetectorService()
    }
    
    /// Analyzes a high-resolution captured bilateral dorsal foot photo.
    /// - Parameter image: High-res UIImage showing left and right feet side-by-side.
    /// - Returns: A quantified `VisualIschemiaResult`.
    public func analyzeBilateralDorsalFeet(image: UIImage) async throws -> VisualIschemiaResult {
        guard let cgImage = ensureUprightCGImage(from: image) else {
            throw VisualInspectionError.invalidImageData
        }
        
        // 1. Run YOLO Object Detection (with fallback to Apple Vision Saliency)
        let (leftBoundingBox, rightBoundingBox) = try await detectBilateralFootRegions(cgImage: cgImage)
        
        // 2. Crop left and right foot ROIs
        guard let leftFootCG = cgImage.cropping(to: leftBoundingBox),
              let rightFootCG = cgImage.cropping(to: rightBoundingBox) else {
            throw VisualInspectionError.feetSegmentationFailed
        }
        
        // 3. Convert ROIs to CIE L*a*b* color coordinates
        let leftLab = calculateAverageCIELAB(from: leftFootCG)
        let rightLab = calculateAverageCIELAB(from: rightFootCG)
        
        // 4. Validate human cutaneous chromaticity to reject non-biological objects (floors, furniture, walls)
        let isLeftSkin = isValidHumanSkin(lab: leftLab)
        let isRightSkin = isValidHumanSkin(lab: rightLab)
        guard isLeftSkin && isRightSkin else {
            if leftLab.L < 18.0 || rightLab.L < 18.0 {
                throw VisualInspectionError.illuminationInadequate
            } else {
                throw VisualInspectionError.noHumanSkinDetected
            }
        }
        
        // 5. Calculate CIE Delta E (CIE 1976 / Euclidean in Lab space) and Lightness disparity
        let deltaE = sqrt(
            pow(leftLab.L - rightLab.L, 2) +
            pow(leftLab.a - rightLab.a, 2) +
            pow(leftLab.b - rightLab.b, 2)
        )
        let lightnessDisparity = leftLab.L - rightLab.L // Positive = Left is paler; Negative = Right is paler
        
        // 6. Evaluate trophic risk markers (pallor, erythema rubor, asymmetry)
        var trophicMarkers: [String] = []
        if deltaE > 5.0 {
            trophicMarkers.append("Marked bilateral color disparity (Delta E > 5.0)")
        }
        if abs(lightnessDisparity) > 8.0 {
            let palerSide = lightnessDisparity > 0 ? "Left" : "Right"
            trophicMarkers.append("Unilateral dorsal blanching / pallor on \(palerSide) foot")
        }
        if leftLab.a < 5.0 || rightLab.a < 5.0 {
            trophicMarkers.append("Loss of microvascular cutaneous erythema (a* < 5.0)")
        }
        
        let normalizedAsymmetry = min(1.0, max(0.0, deltaE / 15.0))
        
        return VisualIschemiaResult(
            deltaE: Double(deltaE),
            lightnessDisparity: Double(lightnessDisparity),
            leftFootLightness: Double(leftLab.L),
            rightFootLightness: Double(rightLab.L),
            asymmetryScore: Double(normalizedAsymmetry),
            trophicRiskFlags: trophicMarkers
        )
    }
    
    // MARK: - Vision Segmentation & ROI Isolation
    
    private func detectBilateralFootRegions(cgImage: CGImage) async throws -> (leftBox: CGRect, rightBox: CGRect) {
        // ลองใช้ YOLO ก่อนเป็นอันดับแรก
        if let yoloResult = try? await yoloDetector.detectFootRegions(cgImage: cgImage) {
            return yoloResult
        }
        
        // Fallback: ใช้ Apple Vision Saliency เดิมหากไม่มีโมเดลหรือตรวจจับไม่พบ
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let midX = width / 2.0
        
        let defaultRoiWidth = width * 0.38
        let defaultRoiHeight = height * 0.70
        let marginX = width * 0.08
        let marginY = height * 0.15
        
        let defaultLeftBox = CGRect(x: marginX, y: marginY, width: defaultRoiWidth, height: defaultRoiHeight)
        let defaultRightBox = CGRect(x: midX + marginX, y: marginY, width: defaultRoiWidth, height: defaultRoiHeight)
        
        let request = VNGenerateAttentionBasedSaliencyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        
        guard let observations = request.results,
              let saliency = observations.first,
              let salientObjects = saliency.salientObjects,
              !salientObjects.isEmpty else {
            return (defaultLeftBox, defaultRightBox)
        }
        
        let pixelBoxes: [CGRect] = salientObjects.map { obs in
            let norm = obs.boundingBox
            return CGRect(
                x: norm.origin.x * width,
                y: max(0, (1.0 - norm.origin.y - norm.height) * height),
                width: norm.width * width,
                height: norm.height * height
            )
        }
        
        let leftCandidates = pixelBoxes.filter { $0.midX < midX }
        let rightCandidates = pixelBoxes.filter { $0.midX >= midX }
        
        let leftBox: CGRect
        if let first = leftCandidates.first {
            leftBox = leftCandidates.dropFirst().reduce(first) { $0.union($1) }.intersection(CGRect(x: 0, y: 0, width: width, height: height))
        } else {
            leftBox = defaultLeftBox
        }
        
        let rightBox: CGRect
        if let first = rightCandidates.first {
            rightBox = rightCandidates.dropFirst().reduce(first) { $0.union($1) }.intersection(CGRect(x: 0, y: 0, width: width, height: height))
        } else {
            rightBox = defaultRightBox
        }
        
        let finalLeft = (leftBox.width > 20 && leftBox.height > 20) ? leftBox : defaultLeftBox
        let finalRight = (rightBox.width > 20 && rightBox.height > 20) ? rightBox : defaultRightBox
        
        return (finalLeft, finalRight)
    }
    
    // MARK: - CIE L*a*b* Color Conversion
    
    private struct CIELAB {
        let L: CGFloat // Lightness (0 = black, 100 = diffuse white)
        let a: CGFloat // Red-Green (+a = red, -a = green)
        let b: CGFloat // Yellow-Blue (+b = yellow, -b = blue)
    }
    
    /// Computes the average CIE L*a*b* coordinates for a given CGImage.
    private func calculateAverageCIELAB(from cgImage: CGImage) -> CIELAB {
        let ciImage = CIImage(cgImage: cgImage)
        
        // Use CIAreaAverage filter to compute mean RGB across the foot region
        let extentVector = CIVector(cgRect: ciImage.extent)
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: ciImage,
            kCIInputExtentKey: extentVector
        ]), let outputImage = filter.outputImage else {
            return CIELAB(L: 50, a: 0, b: 0)
        }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let sRGBColorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        ciContext.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: sRGBColorSpace
        )
        
        let rNorm = CGFloat(bitmap[0]) / 255.0
        let gNorm = CGFloat(bitmap[1]) / 255.0
        let bNorm = CGFloat(bitmap[2]) / 255.0
        
        return sRGBToCIELAB(r: rNorm, g: gNorm, b: bNorm)
    }
    
    /// Standards-compliant sRGB to CIE L*a*b* transform (D65 illuminant).
    private func sRGBToCIELAB(r: CGFloat, g: CGFloat, b: CGFloat) -> CIELAB {
        // Inverse gamma companding
        func pivotRGB(_ val: CGFloat) -> CGFloat {
            return (val > 0.04045) ? pow((val + 0.055) / 1.055, 2.4) : (val / 12.92)
        }
        
        let rLinear = pivotRGB(r) * 100.0
        let gLinear = pivotRGB(g) * 100.0
        let bLinear = pivotRGB(b) * 100.0
        
        // Convert to CIE XYZ (Observer = 2°, Illuminant = D65)
        let X = rLinear * 0.4124 + gLinear * 0.3576 + bLinear * 0.1805
        let Y = rLinear * 0.2126 + gLinear * 0.7152 + bLinear * 0.0722
        let Z = rLinear * 0.0193 + gLinear * 0.1192 + bLinear * 0.9505
        
        // D65 reference white points
        let Xn: CGFloat = 95.047
        let Yn: CGFloat = 100.000
        let Zn: CGFloat = 108.883
        
        func pivotXYZ(_ val: CGFloat) -> CGFloat {
            return (val > 0.008856) ? pow(val, 1.0 / 3.0) : (7.787 * val) + (16.0 / 116.0)
        }
        
        let fx = pivotXYZ(X / Xn)
        let fy = pivotXYZ(Y / Yn)
        let fz = pivotXYZ(Z / Zn)
        
        let L = max(0.0, (116.0 * fy) - 16.0)
        let a = 500.0 * (fx - fy)
        let b = 200.0 * (fy - fz)
        
        return CIELAB(L: L, a: a, b: b)
    }
    
    // MARK: - Cutaneous Chromaticity Validation
    
    /// Validates whether a given CIE L*a*b* reading corresponds to living human cutaneous tissue across Fitzpatrick phototypes (I-VI).
    /// Living skin must contain microvascular hemoglobin (a* in [3.0, 36.0]) and melanin warmth (b* in [3.5, 42.0]),
    /// rejecting non-biological objects, floors, white walls, screens, and clothing.
    private func isValidHumanSkin(lab: CIELAB) -> Bool {
        let isLightnessValid = lab.L >= 18.0 && lab.L <= 92.0
        let isRedChromaValid = lab.a >= 3.0 && lab.a <= 36.0
        let isYellowChromaValid = lab.b >= 3.5 && lab.b <= 42.0
        return isLightnessValid && isRedChromaValid && isYellowChromaValid
    }
    
    // MARK: - Image Orientation Normalization
    
    /// Redraws any UIImage into an upright bitmap matching its visual size and orientation.
    /// Photos captured by the device camera frequently have `.imageOrientation == .right`,
    /// which would otherwise rotate `cgImage` by 90 degrees and corrupt horizontal foot partitioning.
    public func ensureUprightCGImage(from image: UIImage) -> CGImage? {
        guard image.size.width > 0, image.size.height > 0 else { return nil }
        
        if image.imageOrientation == .up, let cgImage = image.cgImage {
            return cgImage
        }
        
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        let normalizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        return normalizedImage.cgImage
    }
}

// MARK: - Test Double (SpyingStub)

#if DEBUG
public final class BilateralFootScannerSpyingStub: BilateralFootScannerServiceProtocol, @unchecked Sendable {
    public private(set) var capturedImages: [UIImage] = []
    public var resultToReturn: VisualIschemiaResult
    public var errorToThrow: Error?
    
    public init(
        resultToReturn: VisualIschemiaResult = .fixture(),
        errorToThrow: Error? = nil
    ) {
        self.resultToReturn = resultToReturn
        self.errorToThrow = errorToThrow
    }
    
    public func analyzeBilateralDorsalFeet(image: UIImage) async throws -> VisualIschemiaResult {
        capturedImages.append(image)
        if let error = errorToThrow {
            throw error
        }
        return resultToReturn
    }
}
#endif

