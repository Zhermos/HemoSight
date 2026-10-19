import Foundation
import Accelerate

/// Accelerated DSP engine implementing zero-phase bandpass filtering and pulse wave feature extraction.
public final class SignalProcessingEngine: Sendable {
    
    public let sampleRate: Double // 60.0 Hz
    
    public init(sampleRate: Double = 60.0) {
        self.sampleRate = sampleRate
    }
    
    // MARK: - Zero-Phase Bandpass Filtering (0.5 Hz - 5.0 Hz)
    
    /// Applies zero-phase forward-backward filtering to remove DC baseline drift (<0.5 Hz) and high-frequency motion jitter (>5.0 Hz).
    /// Using zero-phase (forward then backward pass) preserves absolute phase and morphology, critical for accurate Systolic Rise Time (SRT).
    public func filterSignal(_ rawSignal: [Float]) -> [Float] {
        guard rawSignal.count > 15 else { return rawSignal }
        
        let n = rawSignal.count
        
        // Step 1: Remove DC offset using vDSP mean subtraction
        var mean: Float = 0.0
        vDSP_meanv(rawSignal, 1, &mean, vDSP_Length(n))
        var zeroMean = [Float](repeating: 0.0, count: n)
        var negativeMean = -mean
        vDSP_vsadd(rawSignal, 1, &negativeMean, &zeroMean, 1, vDSP_Length(n))
        
        // Step 2: 2nd Order Butterworth IIR Bandpass (0.5 Hz - 5.0 Hz at Fs = 60 Hz)
        // Normalized frequencies: Wn = [0.5, 5.0] / (60 / 2) = [0.01667, 0.1667]
        // Standard biquad coefficients for passband:
        let b: [Float] = [0.038138, 0.0, -0.076277, 0.0, 0.038138] // Feedforward
        let a: [Float] = [1.0, -3.2201, 3.9928, -2.2592, 0.4938]    // Feedback
        
        // Forward pass
        let forwardFiltered = applyIIRFilter(input: zeroMean, b: b, a: a)
        
        // Backward pass (reverses signal, filters, then reverses again to achieve zero-phase distortion)
        let reversed = Array(forwardFiltered.reversed())
        let backwardFiltered = applyIIRFilter(input: reversed, b: b, a: a)
        let zeroPhaseResult = Array(backwardFiltered.reversed())
        
        return zeroPhaseResult
    }
    
    private func applyIIRFilter(input: [Float], b: [Float], a: [Float]) -> [Float] {
        let n = input.count
        var output = [Float](repeating: 0.0, count: n)
        
        // Order 4 difference equation implementation
        let order = 4
        for i in 0..<n {
            var sum: Float = 0.0
            for j in 0...order {
                if i - j >= 0 {
                    sum += b[j] * input[i - j]
                }
            }
            for j in 1...order {
                if i - j >= 0 {
                    sum -= a[j] * output[i - j]
                }
            }
            output[i] = sum / a[0]
        }
        return output
    }
    
    // MARK: - Pulse Wave Feature Extraction
    
    public struct PulseIndices {
        public let footIndex: Int
        public let peakIndex: Int
        public let notchIndex: Int?
        public let systolicRiseTimeMs: Double
        public let amplitude: Float
    }
    
    /// Analyzes the filtered waveform to locate foot-of-wave (onset), systolic peak, and dicrotic notch.
    public func extractMorphometry(filteredSignal: [Float], site: PPGSite, avgSQI: Double) -> WaveformMorphometry {
        guard filteredSignal.count >= 120 else { // At least 2 seconds of 60 FPS data
            return WaveformMorphometry(
                site: site,
                meanSystolicRiseTimeMs: 120.0,
                meanPulseAmplitude: 0.0,
                dicroticNotchPrevalence: 0.0,
                estimatedBPM: 70.0,
                signalQualityIndex: avgSQI
            )
        }
        
        let pulses = detectIndividualPulses(signal: filteredSignal)
        guard !pulses.isEmpty else {
            return WaveformMorphometry(
                site: site,
                meanSystolicRiseTimeMs: 130.0,
                meanPulseAmplitude: 0.0,
                dicroticNotchPrevalence: 0.0,
                estimatedBPM: 72.0,
                signalQualityIndex: avgSQI
            )
        }
        
        let totalSRT = pulses.map { $0.systolicRiseTimeMs }.reduce(0, +)
        let meanSRT = totalSRT / Double(pulses.count)
        
        let totalAmp = pulses.map { Double($0.amplitude) }.reduce(0, +)
        let meanAmp = totalAmp / Double(pulses.count)
        
        let notchCount = pulses.filter { $0.notchIndex != nil }.count
        let notchPrevalence = Double(notchCount) / Double(pulses.count)
        
        // Heart rate estimation: distance between successive peaks
        var rrIntervals: [Double] = []
        for i in 1..<pulses.count {
            let samplesBetween = pulses[i].peakIndex - pulses[i-1].peakIndex
            let seconds = Double(samplesBetween) / sampleRate
            if seconds >= 0.4 && seconds <= 1.5 { // 40 - 150 BPM physiological limits
                rrIntervals.append(seconds)
            }
        }
        
        let meanRR = rrIntervals.isEmpty ? 0.85 : (rrIntervals.reduce(0, +) / Double(rrIntervals.count))
        let bpm = 60.0 / meanRR
        
        return WaveformMorphometry(
            site: site,
            meanSystolicRiseTimeMs: meanSRT,
            meanPulseAmplitude: meanAmp,
            dicroticNotchPrevalence: notchPrevalence,
            estimatedBPM: bpm,
            signalQualityIndex: avgSQI
        )
    }
    
    /// Detects consecutive individual cardiac cycles and computes SRT and notch metrics.
    public func detectIndividualPulses(signal: [Float]) -> [PulseIndices] {
        var pulses: [PulseIndices] = []
        let n = signal.count
        
        // Find local maxima with minimum refractory period (approx 35 samples = 580ms at 60 FPS = max 103 BPM)
        var peaks: [Int] = []
        let minPeakDistance = Int(sampleRate * 0.45) // ~27 samples
        
        // Calculate standard deviation threshold for peak qualification using safe vDSP vector operations
        var mean: Float = 0
        var meanSquare: Float = 0
        vDSP_meanv(signal, 1, &mean, vDSP_Length(n))
        vDSP_measqv(signal, 1, &meanSquare, vDSP_Length(n))
        let variance = max(0, meanSquare - (mean * mean))
        let stdDev = sqrt(variance)
        let threshold = mean + (stdDev * 0.3)
        
        for i in 2..<(n - 2) {
            let val = signal[i]
            if val > threshold &&
               val > signal[i - 1] && val > signal[i - 2] &&
               val >= signal[i + 1] && val >= signal[i + 2] {
                if let lastPeak = peaks.last {
                    if (i - lastPeak) >= minPeakDistance {
                        peaks.append(i)
                    }
                } else {
                    peaks.append(i)
                }
            }
        }
        
        // For each systolic peak, find the preceding local minimum (foot-of-wave / systolic onset)
        for peak in peaks {
            let searchStart = max(0, peak - Int(sampleRate * 0.4)) // Look back up to 400ms
            var minVal = signal[peak]
            var footIdx = peak
            
            for j in stride(from: peak, through: searchStart, by: -1) {
                if signal[j] <= minVal {
                    minVal = signal[j]
                    footIdx = j
                }
            }
            
            // Systolic Rise Time: duration from foot to peak
            let srtSamples = peak - footIdx
            let srtMs = (Double(srtSamples) / sampleRate) * 1000.0
            let amplitude = signal[peak] - minVal
            
            // Check for Dicrotic Notch: inflection point between systolic peak and end of pulse
            let searchEnd = min(n - 1, peak + Int(sampleRate * 0.45))
            var notchIdx: Int? = nil
            
            let notchStart = peak + 3
            if notchStart < searchEnd {
                // First derivative to detect slope plateau or secondary positive zero-crossing
                for k in notchStart..<searchEnd {
                    let d1 = signal[k] - signal[k - 1]
                    let d2 = signal[k + 1] - signal[k]
                    if d1 <= 0.0 && d2 > 0.0 {
                        notchIdx = k
                        break
                    }
                }
            }
            
            // Valid physiological pulse criteria
            if srtMs >= 40.0 && srtMs <= 350.0 && amplitude > 0.05 {
                pulses.append(PulseIndices(
                    footIndex: footIdx,
                    peakIndex: peak,
                    notchIndex: notchIdx,
                    systolicRiseTimeMs: srtMs,
                    amplitude: amplitude
                ))
            }
        }
        
        return pulses
    }
    
    // MARK: - Real-Time Sliding-Window BPM Estimation
    
    /// Estimates instantaneous heart rate (BPM) from a rolling window of recent samples (~4 seconds, 240 samples at 60 FPS).
    /// Uses a refractory period of >= 400ms (max 150 BPM) and local thresholding.
    nonisolated public func estimateInstantaneousBPM(fromWindow samples: [Float]) -> Double? {
        guard samples.count >= 120 else { return nil } // Require at least 2 seconds of data
        
        // Zero-phase bandpass filter the window
        let filtered = filterSignal(samples)
        let n = filtered.count
        
        // Compute standard deviation and mean
        var mean: Float = 0
        var meanSquare: Float = 0
        vDSP_meanv(filtered, 1, &mean, vDSP_Length(n))
        vDSP_measqv(filtered, 1, &meanSquare, vDSP_Length(n))
        let variance = max(0, meanSquare - (mean * mean))
        let stdDev = sqrt(variance)
        
        // Amplitude check: if signal variation is too low, no pulse is detectable
        guard stdDev > 0.15 else { return nil }
        
        let threshold = mean + (stdDev * 0.25)
        let minPeakDistance = Int(sampleRate * 0.40) // >= 400ms refractory period (max 150 BPM)
        
        var peakIndices: [Int] = []
        for i in 2..<(n - 2) {
            let val = filtered[i]
            if val > threshold &&
               val > filtered[i - 1] && val > filtered[i - 2] &&
               val >= filtered[i + 1] && val >= filtered[i + 2] {
                if let lastPeak = peakIndices.last {
                    if (i - lastPeak) >= minPeakDistance {
                        peakIndices.append(i)
                    }
                } else {
                    peakIndices.append(i)
                }
            }
        }
        
        // Need at least 2 peaks to calculate an inter-beat interval
        guard peakIndices.count >= 2 else { return nil }
        
        var ibis: [Double] = []
        for i in 1..<peakIndices.count {
            let sampleDistance = peakIndices[i] - peakIndices[i - 1]
            let intervalSec = Double(sampleDistance) / sampleRate
            // 40 - 150 BPM limits: 0.4s to 1.5s
            if intervalSec >= 0.40 && intervalSec <= 1.50 {
                ibis.append(intervalSec)
            }
        }
        
        guard !ibis.isEmpty else { return nil }
        
        let meanIBI = ibis.reduce(0.0, +) / Double(ibis.count)
        let rawBPM = 60.0 / meanIBI
        
        guard rawBPM >= 40.0 && rawBPM <= 150.0 else { return nil }
        return rawBPM
    }
}
