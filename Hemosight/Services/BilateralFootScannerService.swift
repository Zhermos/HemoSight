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
    
    public init() {}
    
    /// Analyzes a high-resolution captured bilateral dorsal foot photo.
    /// - Parameter image: High-res UIImage showing left and right feet side-by-side.
    /// - Returns: A quantified `VisualIschemiaResult`.
    public func analyzeBilateralDorsalFeet(image: UIImage) async throws -> VisualIschemiaResult {
        guard let cgImage = ensureUprightCGImage(from: image) else {
            throw VisualInspectionError.invalidImageData
        }
        
        // 1. Run Apple Vision Saliency & Contour Analysis to isolate foot bounding boxes
        let (leftBoundingBox, rightBoundingBox) = try detectBilateralFootRegions(cgImage: cgImage)
        
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
    
    private func detectBilateralFootRegions(cgImage: CGImage) throws -> (leftBox: CGRect, rightBox: CGRect) {
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
    
    private func calculateAverageCIELAB(from cgImage: CGImage) -> CIELAB {
        let ciImage = CIImage(cgImage: cgImage)
        let extentVector = CIVector(cgRect: ciImage.extent)
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: ciImage,
            kCIInputExtentKey: extentVector
        ]), let outputImage = filter.outputImage else {
            return CIELAB(L: 50, a: 0, b: 0)
        }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        ciContext.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )
        
        let r = CGFloat(bitmap[0]) / 255.0
        let g = CGFloat(bitmap[1]) / 255.0
        let b = CGFloat(bitmap[2]) / 255.0
        
        return rgbToCIELAB(r: r, g: g, b: b)
    }
    
    private func rgbToCIELAB(r: CGFloat, g: CGFloat, b: CGFloat) -> CIELAB {
        func pivotRgb(_ n: CGFloat) -> CGFloat {
            n > 0.04045 ? pow((n + 0.055) / 1.055, 2.4) : (n / 12.92)
        }
        
        let rL = pivotRgb(r) * 100.0
        let gL = pivotRgb(g) * 100.0
        let bL = pivotRgb(b) * 100.0
        
        // Standard D65 observer reference illuminant
        let x = rL * 0.4124 + gL * 0.3576 + bL * 0.1805
        let y = rL * 0.2126 + gL * 0.7152 + bL * 0.0722
        let z = rL * 0.0193 + gL * 0.1192 + bL * 0.9505
        
        let refX: CGFloat = 95.047
        let refY: CGFloat = 100.000
        let refZ: CGFloat = 108.883
        
        func pivotXyz(_ n: CGFloat) -> CGFloat {
            n > 0.008856 ? pow(n, 1.0 / 3.0) : (7.787 * n) + (16.0 / 116.0)
        }
        
        let xR = pivotXyz(x / refX)
        let yR = pivotXyz(y / refY)
        let zR = pivotXyz(z / refZ)
        
        let l = (116.0 * yR) - 16.0
        let a = 500.0 * (xR - yR)
        let bVal = 200.0 * (yR - zR)
        
        return CIELAB(L: l, a: a, b: bVal)
    }
    
    private func isValidHumanSkin(lab: CIELAB) -> Bool {
        return lab.L >= 15.0 && lab.L <= 95.0 &&
               lab.a >= 2.0  && lab.a <= 45.0 &&
               lab.b >= 3.0  && lab.b <= 50.0
    }
    
    private func ensureUprightCGImage(from image: UIImage) -> CGImage? {
        if image.imageOrientation == .up, let cg = image.cgImage {
            return cg
        }
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalized?.cgImage
    }
}

// MARK: - Test Double (SpyingStub)

#if DEBUG
public final class BilateralFootScannerSpyingStub: BilateralFootScannerServiceProtocol, @unchecked Sendable {
    public var resultToReturn: VisualIschemiaResult
    public private(set) var capturedImages: [UIImage] = []
    
    public init(resultToReturn: VisualIschemiaResult = VisualIschemiaResult.fixture()) {
        self.resultToReturn = resultToReturn
    }
    
    public func analyzeBilateralDorsalFeet(image: UIImage) async throws -> VisualIschemiaResult {
        capturedImages.append(image)
        return resultToReturn
    }
}
#endif
