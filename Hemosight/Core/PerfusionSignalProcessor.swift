import Foundation
import Accelerate

/// Real-time signal processor for digital Capillary Refill Time (CRT) photoplethysmography.
/// Analyzes red-channel optical reflectance waveforms, filters sensor noise,
/// and computes the microvascular reperfusion duration.
public final class PerfusionSignalProcessor: @unchecked Sendable {
    
    // MARK: - State Machine
    public enum CapturePhase: String, Sendable {
        case idle = "Ready to Scan"
        case acquiringBaseline = "Acquiring Baseline (Hold Steady)"
        case compressing = "Applying Compression (Press Toe Nailbed)"
        case releasing = "Release Pressure Now"
        case calculating = "Analyzing Reperfusion Curve..."
        case completed = "Scan Complete"
        case failed = "Scan Failed - Please Retry"
    }
    
    public private(set) var currentPhase: CapturePhase = .idle
    
    // MARK: - Signal Buffers
    private let sampleCapacity: Int
    private var rawSamples: [Double] = []
    private var filteredSamples: [Double] = []
    private var timestamps: [TimeInterval] = []
    
    private var baselineValue: Double = 0.0
    private var minimumValue: Double = 1.0
    private var compressionReleaseTimestamp: TimeInterval?
    private var recoveryTimestamp: TimeInterval?
    
    // Moving average filter window size
    private let filterWindowSize: Int = 5
    
    public init(sampleCapacity: Int = 600) { // Up to 10 seconds at 60 FPS
        self.sampleCapacity = sampleCapacity
    }
    
    public func reset() {
        rawSamples.removeAll(keepingCapacity: true)
        filteredSamples.removeAll(keepingCapacity: true)
        timestamps.removeAll(keepingCapacity: true)
        baselineValue = 0.0
        minimumValue = 1.0
        compressionReleaseTimestamp = nil
        recoveryTimestamp = nil
        currentPhase = .idle
    }
    
    public func startAcquisition() {
        reset()
        currentPhase = .acquiringBaseline
    }
    
    /// Feeds a new mean red channel intensity value I_R into the processor
    /// - Parameters:
    ///   - redIntensity: Mean intensity value (0.0 ... 1.0)
    ///   - timestamp: Monotonic frame arrival time in seconds
    /// - Returns: Latest filtered value and current phase
    @discardableResult
    public func processSample(redIntensity: Double, timestamp: TimeInterval) -> (filtered: Double, phase: CapturePhase) {
        let clamped = max(0.0, min(1.0, redIntensity))
        rawSamples.append(clamped)
        timestamps.append(timestamp)
        
        // Apply rolling moving-average smoothing filter
        let filtered = computeMovingAverage(for: clamped)
        filteredSamples.append(filtered)
        
        if rawSamples.count > sampleCapacity {
            rawSamples.removeFirst()
            filteredSamples.removeFirst()
            timestamps.removeFirst()
        }
        
        // Evaluate Phase Transitions
        evaluateStateTransitions(currentValue: filtered, timestamp: timestamp)
        
        return (filtered, currentPhase)
    }
    
    private func computeMovingAverage(for latest: Double) -> Double {
        let count = min(filteredSamples.count + 1, filterWindowSize)
        guard count > 1 else { return latest }
        
        let sliceStart = max(0, filteredSamples.count - (count - 1))
        let sum = filteredSamples[sliceStart...].reduce(0.0, +) + latest
        return sum / Double(count)
    }
    
    private func evaluateStateTransitions(currentValue: Double, timestamp: TimeInterval) {
        switch currentPhase {
        case .idle:
            break
            
        case .acquiringBaseline:
            // Need at least 30 frames (~0.5s) of steady reflectance to lock baseline
            if filteredSamples.count >= 30 {
                let recentSlice = filteredSamples.suffix(30)
                let mean = recentSlice.reduce(0.0, +) / Double(recentSlice.count)
                let variance = recentSlice.map { pow($0 - mean, 2) }.reduce(0.0, +) / Double(recentSlice.count)
                
                // If signal is reasonably stable
                if variance < 0.005 && mean > 0.3 {
                    baselineValue = mean
                    currentPhase = .compressing
                }
            }
            
        case .compressing:
            // Blanching causes dramatic reflectance drop as capillaries empty
            if currentValue < minimumValue {
                minimumValue = currentValue
            }
            // Significant drop detected (> 25% drop from baseline)
            if baselineValue > 0 && currentValue < (baselineValue * 0.75) {
                // Wait for bottom plateau or user release
            }
            
        case .releasing:
            if compressionReleaseTimestamp == nil {
                compressionReleaseTimestamp = timestamp
                minimumValue = currentValue
            }
            
            // Check for 90% recovery: I_90% = I_min + 0.90 * (I_base - I_min)
            let recoveryTarget = minimumValue + 0.90 * (baselineValue - minimumValue)
            if currentValue >= recoveryTarget && recoveryTimestamp == nil {
                recoveryTimestamp = timestamp
                currentPhase = .completed
            }
            
            // Timeout if recovery exceeds 8 seconds (severe ischemia or dropped contact)
            if let releaseTime = compressionReleaseTimestamp, (timestamp - releaseTime) > 8.0 {
                recoveryTimestamp = timestamp
                currentPhase = .completed
            }
            
        case .calculating, .completed, .failed:
            break
        }
    }
    
    /// User or UI trigger to notify that physical compression has ceased
    public func markReleaseTriggered(at timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        if currentPhase == .compressing || currentPhase == .acquiringBaseline {
            currentPhase = .releasing
            compressionReleaseTimestamp = timestamp
            // Set minimum value to the lowest observed sample during compression
            if let lowest = filteredSamples.min() {
                minimumValue = lowest
            }
        }
    }
    
    /// Computes the final CRT measurement structure once data collection completes
    public func finalizeMeasurement() -> CRTMeasurement? {
        guard baselineValue > 0.0 else { return nil }
        
        let crtDuration: Double
        if let release = compressionReleaseTimestamp, let rec = recoveryTimestamp {
            crtDuration = max(0.5, rec - release)
        } else if let release = compressionReleaseTimestamp {
            let lastTime = timestamps.last ?? (release + 4.5)
            crtDuration = max(0.5, lastTime - release)
        } else {
            crtDuration = 2.0
        }
        
        let threshold = minimumValue + 0.90 * (baselineValue - minimumValue)
        
        return CRTMeasurement(
            rawRedIntensities: Array(rawSamples),
            filteredRedIntensities: Array(filteredSamples),
            baselineIntensity: baselineValue,
            minimumIntensity: minimumValue,
            recoveryThresholdIntensity: threshold,
            crtSeconds: crtDuration,
            frameRate: 60.0
        )
    }
    
    // MARK: - Waveform Exporters
    public var currentWaveform: [Double] {
        return filteredSamples
    }
}
