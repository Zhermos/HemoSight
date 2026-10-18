import Foundation
import AVFoundation
import CoreMedia
import Combine
import os

/// Status flags indicating whether camera positioning & pressure is clinically valid.
public enum CameraContactState: String, Sendable {
    case notCovered = "Place fingertip/toe firmly over camera lens & flash"
    case tooLight = "Light leak detected — cover the lens completely"
    case overPressed = "Pressing too hard — relax pressure slightly to avoid blanching vessels"
    case optimal = "Signal Quality Optimal — keep steady"
}

/// Errors occurring during camera PPG stream acquisition.
public enum CameraPPGError: LocalizedError {
    case cameraUnavailable
    case torchUnavailable
    case cannotSetFrameRate
    case configurationFailed(String)
    case sessionInterrupted
    
    public var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "Rear wide-angle camera is not available on this device."
        case .torchUnavailable:
            return "Rear LED illumination (flash) could not be activated."
        case .cannotSetFrameRate:
            return "Could not lock camera frame rate to 60 FPS."
        case .configurationFailed(let reason):
            return "AVCaptureSession configuration failed: \(reason)"
        case .sessionInterrupted:
            return "Camera stream was interrupted."
        }
    }
}

/// Protocol abstracting real-time camera PPG signal acquisition for testability and mock injection.
public protocol CameraPPGServiceProtocol: Sendable {
    var sampleSubject: PassthroughSubject<PPGDataPoint, Never> { get }
    var contactStateSubject: CurrentValueSubject<CameraContactState, Never> { get }
    var signalQualitySubject: CurrentValueSubject<Double, Never> { get }
    
    func startCapture() async throws
    func stopCapture()
}

/// AVFoundation pipeline capturing frames locked at 60 FPS with torch on, manual exposure, and real-time SQI checking.
public final class CameraPPGService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, CameraPPGServiceProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.hemosight.camera.sessionQueue", qos: .userInitiated)
    
    private var isConfigured = false
    private let scanStartTimeLock = OSAllocatedUnfairLock<TimeInterval?>(initialState: nil)
    #if targetEnvironment(simulator)
    private var simulatorTimerTask: Task<Void, Never>?
    #endif
    
    // Real-time publishers
    public let sampleSubject = PassthroughSubject<PPGDataPoint, Never>()
    public let contactStateSubject = CurrentValueSubject<CameraContactState, Never>(.notCovered)
    public let signalQualitySubject = CurrentValueSubject<Double, Never>(0.0)
    
    public override init() {
        super.init()
    }
    
    // MARK: - Configuration & Lifecycle
    
    /// Configures the AVCaptureSession with 60 FPS, locked exposure/focus/WB, and torch enabled.
    public func startCapture() async throws {
        #if !targetEnvironment(simulator)
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else { throw CameraPPGError.configurationFailed("Camera access denied.") }
        } else if status == .denied || status == .restricted {
            throw CameraPPGError.configurationFailed("Camera permission is denied or restricted in Settings.")
        }
        #endif
        
        #if targetEnvironment(simulator)
        startSimulatorStream()
        #else
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: CameraPPGError.sessionInterrupted)
                    return
                }
                do {
                    if !self.isConfigured {
                        try self.configureSession()
                        self.isConfigured = true
                    }
                    self.scanStartTimeLock.withLock { $0 = ProcessInfo.processInfo.systemUptime }
                    self.captureSession.startRunning()
                    self.turnTorchOn(level: 0.8)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        #endif
    }
    
    public func stopCapture() {
        #if targetEnvironment(simulator)
        simulatorTimerTask?.cancel()
        simulatorTimerTask = nil
        scanStartTimeLock.withLock { $0 = nil }
        contactStateSubject.send(.notCovered)
        signalQualitySubject.send(0.0)
        #else
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            self.turnTorchOff()
            self.scanStartTimeLock.withLock { $0 = nil }
        }
        #endif
    }
    
    #if targetEnvironment(simulator)
    private func startSimulatorStream() {
        simulatorTimerTask?.cancel()
        let startTime = ProcessInfo.processInfo.systemUptime
        scanStartTimeLock.withLock { $0 = startTime }
        
        contactStateSubject.send(.optimal)
        signalQualitySubject.send(0.95)
        
        simulatorTimerTask = Task { [weak self] in
            var sampleIndex: UInt64 = 0
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 16_666_667) // ~60 FPS (1/60s)
                guard let self = self, !Task.isCancelled else { break }
                
                let current = ProcessInfo.processInfo.systemUptime
                let timestamp = max(0.0, current - startTime)
                
                // Synthesize 1.1 Hz pulsatile PPG signal with systolic peak and dicrotic notch
                let phase = (Double(sampleIndex % 55) / 55.0) * 2.0 * Double.pi
                let cardiacWave = sin(phase) + 0.35 * sin(2.0 * phase)
                let greenValue = Float(140.0 + (cardiacWave * 25.0))
                let redValue: Float = 220.0
                
                let point = PPGDataPoint(
                    timestamp: timestamp,
                    filteredGreen: greenValue,
                    rawGreen: greenValue,
                    rawRed: redValue
                )
                
                self.sampleSubject.send(point)
                sampleIndex += 1
            }
        }
    }
    #endif
    
    private func configureSession() throws {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .vga640x480 // Optimal resolution for fast real-time pixel extraction
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            captureSession.commitConfiguration()
            throw CameraPPGError.cameraUnavailable
        }
        
        let videoInput = try AVCaptureDeviceInput(device: camera)
        guard captureSession.canAddInput(videoInput) else {
            captureSession.commitConfiguration()
            throw CameraPPGError.configurationFailed("Cannot add video input.")
        }
        captureSession.addInput(videoInput)
        
        // 60 FPS configuration
        try camera.lockForConfiguration()
        defer { camera.unlockForConfiguration() }
        
        // Set frame rate to strictly 60 FPS
        var frameRateSupported = false
        for range in camera.activeFormat.videoSupportedFrameRateRanges {
            if range.maxFrameRate >= 60.0 && range.minFrameRate <= 60.0 {
                camera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 60)
                camera.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 60)
                frameRateSupported = true
                break
            }
        }
        
        // Lock Focus at macro/minimum distance
        if camera.isFocusModeSupported(.locked) {
            camera.focusMode = .locked
        }
        
        // Lock Exposure
        if camera.isExposureModeSupported(.locked) {
            camera.exposureMode = .locked
        }
        
        // Lock White Balance
        if camera.isWhiteBalanceModeSupported(.locked) {
            camera.whiteBalanceMode = .locked
        }
        
        // Configure Output
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        
        let videoQueue = DispatchQueue(label: "com.hemosight.camera.videoQueue", qos: .userInteractive)
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        
        guard captureSession.canAddOutput(videoOutput) else {
            captureSession.commitConfiguration()
            throw CameraPPGError.configurationFailed("Cannot add video output.")
        }
        captureSession.addOutput(videoOutput)
        
        captureSession.commitConfiguration()
    }
    
    private func turnTorchOn(level: Float = 0.8) {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              camera.hasTorch,
              camera.isTorchModeSupported(.on) else { return }
        do {
            try camera.lockForConfiguration()
            defer { camera.unlockForConfiguration() }
            try camera.setTorchModeOn(level: level)
        } catch {
            print("Failed to turn torch on: \(error)")
        }
    }
    
    private func turnTorchOff() {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              camera.hasTorch else { return }
        do {
            try camera.lockForConfiguration()
            defer { camera.unlockForConfiguration() }
            if camera.isTorchModeSupported(.off) {
                camera.torchMode = .off
            }
        } catch {
            print("Failed to turn torch off: \(error)")
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        // Extract green and red channel averages from central 50% ROI
        let startX = width / 4
        let endX = (width * 3) / 4
        let startY = height / 4
        let endY = (height * 3) / 4
        
        var redSum: UInt64 = 0
        var greenSum: UInt64 = 0
        var sampleCount: UInt64 = 0
        
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        // Stride by 4 for BGRA format; sample every 2nd pixel for compute efficiency
        for y in stride(from: startY, to: endY, by: 2) {
            let rowOffset = y * bytesPerRow
            for x in stride(from: startX, to: endX, by: 2) {
                let pixelOffset = rowOffset + (x * 4)
                let b = buffer[pixelOffset]
                let g = buffer[pixelOffset + 1]
                let r = buffer[pixelOffset + 2]
                
                redSum += UInt64(r)
                greenSum += UInt64(g)
                sampleCount += 1
            }
        }
        
        guard sampleCount > 0 else { return }
        
        let meanRed = Float(redSum) / Float(sampleCount)
        let meanGreen = Float(greenSum) / Float(sampleCount)
        
        // Signal Quality Index (SQI) and contact analysis
        // 1. If meanRed < 60 -> Not properly covering camera & flash
        // 2. If meanRed > 240 && meanGreen > 230 -> Over-saturation (light leak)
        // 3. If meanRed / (meanGreen + 1) > 8.0 && meanGreen < 15 -> Over-pressing (hemodynamic blanching)
        let contactState: CameraContactState
        let sqi: Double
        
        if meanRed < 60.0 {
            contactState = .notCovered
            sqi = 0.0
        } else if meanRed > 245.0 && meanGreen > 235.0 {
            contactState = .tooLight
            sqi = 0.2
        } else if (meanRed / (meanGreen + 0.1)) > 10.0 && meanGreen < 12.0 {
            contactState = .overPressed
            sqi = 0.35
        } else {
            contactState = .optimal
            sqi = 0.95
        }
        
        contactStateSubject.send(contactState)
        signalQualitySubject.send(sqi)
        
        let timestamp: Double = scanStartTimeLock.withLock { start in
            if let start = start {
                let current = ProcessInfo.processInfo.systemUptime
                return max(0.0, current - start)
            } else {
                return 0.0
            }
        }
        
        let point = PPGDataPoint(
            timestamp: timestamp,
            filteredGreen: meanGreen, // Raw initial placeholder; filtered via SignalProcessingEngine
            rawGreen: meanGreen,
            rawRed: meanRed
        )
        sampleSubject.send(point)
    }
}

// MARK: - Test Double (SpyingStub)

#if DEBUG
public final class CameraPPGServiceSpyingStub: CameraPPGServiceProtocol, @unchecked Sendable {
    public let sampleSubject = PassthroughSubject<PPGDataPoint, Never>()
    public let contactStateSubject = CurrentValueSubject<CameraContactState, Never>(.notCovered)
    public let signalQualitySubject = CurrentValueSubject<Double, Never>(0.0)
    
    public private(set) var startCaptureCallCount = 0
    public private(set) var stopCaptureCallCount = 0
    public var errorToThrowOnStart: Error?
    
    public init(errorToThrowOnStart: Error? = nil) {
        self.errorToThrowOnStart = errorToThrowOnStart
    }
    
    public func startCapture() async throws {
        startCaptureCallCount += 1
        if let error = errorToThrowOnStart {
            throw error
        }
    }
    
    public func stopCapture() {
        stopCaptureCallCount += 1
    }
    
    public func emitSample(green: Float, red: Float = 200.0, timestamp: Double = 0.0, sqi: Double = 0.95, contactState: CameraContactState = .optimal) {
        contactStateSubject.send(contactState)
        signalQualitySubject.send(sqi)
        let point = PPGDataPoint(timestamp: timestamp, filteredGreen: green, rawGreen: green, rawRed: red)
        sampleSubject.send(point)
    }
}
#endif

