import Foundation
import UIKit
import Vision
import CoreML

/// Protocol defining the contract for YOLO-based dorsal foot detection.
public protocol YOLOFootDetectorServiceProtocol: Sendable {
    func detectFootRegions(cgImage: CGImage) async throws -> (leftBox: CGRect, rightBox: CGRect)?
}

/// Service executing YOLO object detection (e.g. YOLOv8 / YOLOv11) via Apple CoreML and Vision frameworks.
public final class YOLOFootDetectorService: YOLOFootDetectorServiceProtocol, @unchecked Sendable {
    
    private var visionModel: VNCoreMLModel?
    private let modelName: String
    
    public init(modelName: String = "YOLOFootDetector") {
        self.modelName = modelName
        self.visionModel = Self.loadVisionModel(named: modelName)
    }
    
    private static func loadVisionModel(named name: String) -> VNCoreMLModel? {
        let possibleUrls = [
            #if SWIFT_PACKAGE
            Bundle.module.url(forResource: name, withExtension: "mlmodelc"),
            Bundle.module.url(forResource: name, withExtension: "mlpackage"),
            #endif
            Bundle.main.url(forResource: name, withExtension: "mlmodelc"),
            Bundle.main.url(forResource: name, withExtension: "mlpackage")
        ].compactMap { $0 }
        
        guard let url = possibleUrls.first else { return nil }
        
        do {
            let compiledUrl: URL
            if url.pathExtension == "mlpackage" {
                compiledUrl = try MLModel.compileModel(at: url)
            } else {
                compiledUrl = url
            }
            let config = MLModelConfiguration()
            config.computeUnits = .all // Utilizes Apple Neural Engine (ANE) + GPU + CPU
            let mlModel = try MLModel(contentsOf: compiledUrl, configuration: config)
            return try VNCoreMLModel(for: mlModel)
        } catch {
            return nil
        }
    }
    
    public func detectFootRegions(cgImage: CGImage) async throws -> (leftBox: CGRect, rightBox: CGRect)? {
        guard let vModel = visionModel else {
            // Model file not yet in bundle; gracefully fallback to Apple Vision Saliency
            return nil
        }
        
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let midX = width / 2.0
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: vModel) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = request.results as? [VNRecognizedObjectObservation], !results.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let validDetections = results.filter { $0.confidence >= 0.40 }
                guard !validDetections.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let pixelBoxes: [(box: CGRect, label: String, confidence: Float)] = validDetections.map { obs in
                    let norm = obs.boundingBox
                    let pixelRect = CGRect(
                        x: norm.origin.x * width,
                        y: max(0, (1.0 - norm.origin.y - norm.height) * height),
                        width: norm.width * width,
                        height: norm.height * height
                    )
                    let topLabel = obs.labels.first?.identifier.lowercased() ?? "foot"
                    return (pixelRect, topLabel, obs.confidence)
                }
                
                // 1. Check label-specific matches (left_foot vs right_foot)
                let leftByLabel = pixelBoxes.first(where: { $0.label.contains("left") })?.box
                let rightByLabel = pixelBoxes.first(where: { $0.label.contains("right") })?.box
                if let left = leftByLabel, let right = rightByLabel {
                    continuation.resume(returning: (left, right))
                    return
                }
                
                // 2. Spatial partitioning (left half vs right half)
                let leftCandidates = pixelBoxes.map(\.box).filter { $0.midX < midX }
                let rightCandidates = pixelBoxes.map(\.box).filter { $0.midX >= midX }
                
                guard let leftBox = leftCandidates.first, let rightBox = rightCandidates.first else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let clampedBounds = CGRect(x: 0, y: 0, width: width, height: height)
                continuation.resume(returning: (leftBox.intersection(clampedBounds), rightBox.intersection(clampedBounds)))
            }
            
            request.imageCropAndScaleOption = .scaleFit
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

// MARK: - Test Double (SpyingStub)

#if DEBUG
public final class YOLOFootDetectorServiceSpyingStub: YOLOFootDetectorServiceProtocol, @unchecked Sendable {
    public var stubbedResult: (leftBox: CGRect, rightBox: CGRect)?
    public private(set) var detectCallCount = 0
    
    public init(stubbedResult: (leftBox: CGRect, rightBox: CGRect)? = nil) {
        self.stubbedResult = stubbedResult
    }
    
    public func detectFootRegions(cgImage: CGImage) async throws -> (leftBox: CGRect, rightBox: CGRect)? {
        detectCallCount += 1
        return stubbedResult
    }
}
#endif
