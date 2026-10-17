import Foundation
import AVFoundation
import CoreVideo
import CoreGraphics
import Combine

/// AVFoundation Camera and Torch Controller for high-speed toe nailbed video streaming.
/// Captures 60 FPS frames, locks continuous torch illumination, extracts mean red channel
/// intensity within the target ROI, and streams real-time data to PerfusionSignalProcessor.
public final class CRTCameraManager: NSObject, ObservableObject, @unchecked Sendable {
    
    // MARK: - Published Reactive State for SwiftUI
    @Published public var currentRedIntensity: Double = 0.0
    @Published public var capturePhase: PerfusionSignalProcessor.CapturePhase = .idle
    @Published public var waveformHistory: [Double] = []
    @Published public var isTorchActive: Bool = false
    @Published public var isSessionRunning: Bool = false
    @Published public var latestMeasurement: CRTMeasurement?
    @Published public var errorMessage: String?
    @Published public var isSimulated: Bool = false
    
    // MARK: - Camera Hardware Components
    public let captureSession = AVCaptureSession()
    private var videoDevice: AVCaptureDevice?
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.hemosight.camera.sessionQueue", qos: .userInitiated)
    private let processingQueue = DispatchQueue(label: "com.hemosight.camera.processingQueue", qos: .userInteractive)
    
    // MARK: - Signal Processor
    public let signalProcessor = PerfusionSignalProcessor()
    
    // Central ROI bounding box normalized (0.0 - 1.0)
    // Target 25% central area over the toe nailbed
    private let roiRect = CGRect(x: 0.375, y: 0.375, width: 0.25, height: 0.25)
    
    // Timer for simulation on Mac / Simulators
    private var simulationTimer: AnyCancellable?
    
    public override init() {
        super.init()
    }
    
    // MARK: - Camera Setup
    
    public func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.configureSession()
        }
    }
    
    private func configureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1920x1080
        
        // Find back camera with ultra-wide or wide-angle capability
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            DispatchQueue.main.async {
                self.errorMessage = "Back camera not available. Switching to simulation mode."
                self.isSimulated = true
            }
            captureSession.commitConfiguration()
            return
        }
        
        self.videoDevice = device
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            // Configure 60 FPS format if supported
            try device.lockForConfiguration()
            
            // Lock focus to close range (macro for toe nailbed)
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isSmoothAutoFocusSupported {
                device.isSmoothAutoFocusEnabled = true
            }
            
            // Set 60 FPS active format
            for format in device.formats {
                for range in format.videoSupportedFrameRateRanges {
                    if range.maxFrameRate >= 60.0 {
                        device.activeFormat = format
                        device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 60)
                        device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 60)
                        break
                    }
                }
            }
            
            device.unlockForConfiguration()
            
            // Configure Video Data Output for 32BGRA
            videoDataOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.setSampleBufferDelegate(self, queue: processingQueue)
            
            if captureSession.canAddOutput(videoDataOutput) {
                captureSession.addOutput(videoDataOutput)
            }
            
            captureSession.commitConfiguration()
            
            DispatchQueue.main.async {
                self.isSimulated = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to initialize camera: \(error.localizedDescription)"
                self.isSimulated = true
            }
            captureSession.commitConfiguration()
        }
    }
    
    // MARK: - Session Control
    
    public func startScanning() {
        signalProcessor.startAcquisition()
        
        if isSimulated || videoDevice == nil {
            startSimulationStream()
            return
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
            self.setTorch(enabled: true)
            DispatchQueue.main.async {
                self.isSessionRunning = true
            }
        }
    }
    
    public func stopScanning() {
        simulationTimer?.cancel()
        simulationTimer = nil
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.setTorch(enabled: false)
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            DispatchQueue.main.async {
                self.isSessionRunning = false
            }
        }
    }
    
    public func triggerReleaseBlanching() {
        signalProcessor.markReleaseTriggered()
        DispatchQueue.main.async {
            self.capturePhase = self.signalProcessor.currentPhase
        }
    }
    
    // MARK: - Torch Control
    
    public func setTorch(enabled: Bool) {
        guard let device = videoDevice, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            if enabled {
                try device.setTorchModeOn(level: 1.0)
            } else {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
            DispatchQueue.main.async {
                self.isTorchActive = enabled
            }
        } catch {
            print("Torch configuration failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Simulation Mode (Simulator / Preview)
    
    public func startSimulationStream() {
        simulationTimer?.cancel()
        signalProcessor.startAcquisition()
        isSimulated = true
        isSessionRunning = true
        
        var step = 0
        let totalSteps = 240 // 4 seconds at 60 FPS
        let baseline = 0.82
        let minVal = 0.36
        
        simulationTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                step += 1
                let intensity: Double
                let now = ProcessInfo.processInfo.systemUptime
                
                if step < 40 {
                    // Pre-compression baseline
                    intensity = baseline + Double.random(in: -0.01...0.01)
                } else if step < 90 {
                    // Active blanching compression
                    let factor = Double(step - 40) / 50.0
                    intensity = baseline - (baseline - minVal) * factor + Double.random(in: -0.01...0.01)
                } else if step == 90 {
                    // Release trigger
                    intensity = minVal
                    self.triggerReleaseBlanching()
                } else {
                    // Capillary reperfusion recovery curve
                    let recStep = Double(step - 90)
                    let sigmoid = 1.0 / (1.0 + exp(-0.08 * (recStep - 45.0)))
                    intensity = minVal + (baseline - minVal) * sigmoid + Double.random(in: -0.01...0.01)
                }
                
                let (filtered, phase) = self.signalProcessor.processSample(redIntensity: intensity, timestamp: now)
                self.currentRedIntensity = filtered
                self.capturePhase = phase
                self.waveformHistory = self.signalProcessor.currentWaveform
                
                if step >= totalSteps || phase == .completed {
                    self.simulationTimer?.cancel()
                    self.latestMeasurement = self.signalProcessor.finalizeMeasurement()
                }
            }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CRTCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        
        // Define Central ROI over toe nailbed
        let roiX = Int(Double(width) * roiRect.origin.x)
        let roiY = Int(Double(height) * roiRect.origin.y)
        let roiW = Int(Double(width) * roiRect.size.width)
        let roiH = Int(Double(height) * roiRect.size.height)
        
        var redSum: UInt64 = 0
        var pixelCount: UInt64 = 0
        
        // Step stride of 2 for fast cache-friendly spatial averaging
        let strideStep = 2
        for y in stride(from: roiY, to: roiY + roiH, by: strideStep) {
            let rowPtr = baseAddress.advanced(by: y * bytesPerRow).assumingMemoryBound(to: UInt8.self)
            for x in stride(from: roiX, to: roiX + roiW, by: strideStep) {
                let pixelIndex = x * 4 // BGRA format
                // In BGRA: [B, G, R, A] -> Red is at offset 2
                let redVal = rowPtr[pixelIndex + 2]
                redSum += UInt64(redVal)
                pixelCount += 1
            }
        }
        
        let meanRed = pixelCount > 0 ? (Double(redSum) / Double(pixelCount)) / 255.0 : 0.0
        let timestamp = ProcessInfo.processInfo.systemUptime
        
        let (filtered, phase) = signalProcessor.processSample(redIntensity: meanRed, timestamp: timestamp)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentRedIntensity = filtered
            self.capturePhase = phase
            self.waveformHistory = self.signalProcessor.currentWaveform
            
            if phase == .completed && self.latestMeasurement == nil {
                self.latestMeasurement = self.signalProcessor.finalizeMeasurement()
                self.stopScanning()
            }
        }
    }
}
