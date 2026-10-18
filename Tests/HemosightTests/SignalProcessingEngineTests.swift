import Testing
import Foundation
@testable import Hemosight

@Suite("Signal Processing Engine Tests")
struct SignalProcessingEngineTests {
    
    // MARK: - Zero-Phase Bandpass Filter Tests
    
    @Test("Short signal below minimum length threshold returns unmodified without crashing")
    func testFilterShortSignalSafety() {
        // Given
        let engine = SignalProcessingEngine(sampleRate: 60.0)
        let shortSignal: [Float] = [1.0, 2.0, 3.0]
        
        // When
        let filtered = engine.filterSignal(shortSignal)
        
        // Then
        #expect(filtered == shortSignal)
    }
    
    @Test("Zero-phase bandpass filter removes large DC bias while maintaining sample count")
    func testZeroPhaseFilteringRemovesDCBias() {
        // Given
        let engine = SignalProcessingEngine(sampleRate: 60.0)
        let sampleCount = 180
        let dcOffset: Float = 150.0
        let pureSine: [Float] = (0..<sampleCount).map { i in
            dcOffset + 5.0 * sin(Float(i) * 2.0 * Float.pi / 60.0) // 1 Hz wave with 150 DC offset
        }
        
        // When
        let filtered = engine.filterSignal(pureSine)
        
        // Then
        #expect(filtered.count == sampleCount)
        let meanVal = filtered.reduce(0.0, +) / Float(filtered.count)
        #expect(abs(meanVal) < 1.0) // Centered around 0 after zero-phase filtering
    }
    
    // MARK: - Peak & Cycle Detection Tests
    
    @Test("Synthetic pulsatile waveform yields valid morphological intervals")
    func testPulsatileCycleDetection() throws {
        // Given
        let engine = SignalProcessingEngine(sampleRate: 60.0)
        let sampleCount = 360 // 6 seconds at 60 FPS
        var syntheticSignal = [Float](repeating: 0.0, count: sampleCount)
        
        // Generate ~1.0 Hz pulses (60 samples per cycle)
        for i in 0..<sampleCount {
            let phase = Float(i % 60)
            if phase < 10 {
                syntheticSignal[i] = (phase / 10.0) * 2.0
            } else if phase < 25 {
                syntheticSignal[i] = 2.0 - ((phase - 10.0) / 15.0) * 0.9
            } else {
                syntheticSignal[i] = 1.1 - ((phase - 25.0) / 35.0) * 1.1
            }
        }
        
        // When
        let pulses = engine.detectIndividualPulses(signal: syntheticSignal)
        
        // Then
        let firstPulse = try #require(pulses.first)
        #expect(pulses.count >= 4)
        #expect(firstPulse.systolicRiseTimeMs >= 40.0 && firstPulse.systolicRiseTimeMs <= 350.0)
        #expect(firstPulse.amplitude > 0.1)
        #expect(firstPulse.peakIndex > firstPulse.footIndex)
    }
    
    @Test("Buffer edge boundary: peak placed at extreme end does not trigger index out of bounds")
    func testBufferEdgeSafety() {
        // Given
        let engine = SignalProcessingEngine(sampleRate: 60.0)
        var edgeSignal = [Float](repeating: 0.2, count: 65)
        edgeSignal[62] = 2.5 // Peak right at buffer tail
        edgeSignal[61] = 1.2
        edgeSignal[63] = 1.1
        
        // When
        let pulses = engine.detectIndividualPulses(signal: edgeSignal)
        
        // Then: Should execute safely without fatal error: Range requires lowerBound <= upperBound
        #expect(pulses.count >= 0)
    }
    
    // MARK: - Morphometry Extraction Tests
    
    @Test("Morphometry extraction on short buffer returns safe physiological fallback")
    func testShortBufferMorphometryFallback() {
        // Given
        let engine = SignalProcessingEngine(sampleRate: 60.0)
        let shortBuffer = [Float](repeating: 0.5, count: 50) // Less than 120 samples
        
        // When
        let morph = engine.extractMorphometry(filteredSignal: shortBuffer, site: .toe, avgSQI: 0.88)
        
        // Then
        #expect(morph.site == .toe)
        #expect(morph.meanSystolicRiseTimeMs == 120.0)
        #expect(morph.meanPulseAmplitude == 0.0)
        #expect(morph.signalQualityIndex == 0.88)
    }
    
    @Test(
        "Pulse analysis identifies heart rate within expected physiological bounds",
        arguments: [
            (60, 60.0), // 60 samples per beat at 60 Hz = 60 BPM
            (45, 80.0), // 45 samples per beat at 60 Hz = 80 BPM
            (36, 100.0) // 36 samples per beat at 60 Hz = 100 BPM
        ]
    )
    func testHeartRateEstimationFromPeriods(periodSamples: Int, expectedBPM: Double) {
        // Given
        let engine = SignalProcessingEngine(sampleRate: 60.0)
        let totalSamples = 300
        var signal = [Float](repeating: 0.0, count: totalSamples)
        
        for i in 0..<totalSamples {
            let phase = Float(i % periodSamples)
            if phase < 8 {
                signal[i] = (phase / 8.0) * 1.5
            } else {
                signal[i] = 1.5 - ((phase - 8.0) / Float(periodSamples - 8)) * 1.5
            }
        }
        
        // When
        let morph = engine.extractMorphometry(filteredSignal: signal, site: .finger, avgSQI: 0.95)
        
        // Then (Allowing small tolerance due to integer sample quantization)
        #expect(abs(morph.estimatedBPM - expectedBPM) < 6.0)
    }
}
