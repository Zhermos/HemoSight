import Foundation
import SwiftUI
import Combine

/// Current step in the multi-stage vascular screening workflow.
public enum ScreeningStep: Int, CaseIterable, Identifiable {
    case step1VisualPhoto = 1
    case step2FingerPPG = 2
    case step3ToePPG = 3
    case step4Dashboard = 4
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .step1VisualPhoto: return "Step 1: Bilateral Foot Photo"
        case .step2FingerPPG: return "Step 2: Fingertip Pulse (Baseline)"
        case .step3ToePPG: return "Step 3: Big Toe Pulse (Distal)"
        case .step4Dashboard: return "Step 4: Clinical Risk Assessment"
        }
    }
}

/// Main application view model managing screening states, hardware streaming, and clinical scoring.
@Observable
@MainActor
public final class ScreeningWorkflowViewModel {
    
    // Workflow State
    public var currentStep: ScreeningStep = .step1VisualPhoto
    public var isProcessing: Bool = false
    public var errorMessage: String?
    
    // Patient Data
    public var patientName: String = "Eleanor Vance"
    public var patientAge: Int = 74
    
    // Step 1: Visual Foot Photo Data
    public var capturedFootImage: UIImage?
    public var visualResult: VisualIschemiaResult?
    
    // Step 2 & 3: PPG Data
    public var isRecordingPPG: Bool = false
    public var scanSecondsRemaining: Int = 30
    public var currentContactState: CameraContactState = .notCovered
    public var currentSQI: Double = 0.0
    
    // Real-time live waveforms for Swift Charts (rolling buffer)
    public var liveWaveformPoints: [PPGDataPoint] = []
    @ObservationIgnored public var fingerRawSamples: [Float] = []
    @ObservationIgnored public var fingerFilteredSamples: [Float] = []
    @ObservationIgnored public var fingerSQISamples: [Double] = []
    public var fingerMorphometry: WaveformMorphometry?
    
    @ObservationIgnored public var toeRawSamples: [Float] = []
    @ObservationIgnored public var toeFilteredSamples: [Float] = []
    @ObservationIgnored public var toeSQISamples: [Double] = []
    public var toeMorphometry: WaveformMorphometry?
    
    // Step 4: Final Assessment
    public var finalReport: ComprehensivePADReport?
    public var generatedPDFData: Data?
    
    // Services
    private let visualScanner: any BilateralFootScannerServiceProtocol
    private let cameraPPG: any CameraPPGServiceProtocol
    private let dspEngine: SignalProcessingEngine
    private let classifier: VascularRiskClassifier
    private let reportService: any ReportGenerationServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private var timerTask: Task<Void, Never>?
    @ObservationIgnored private var sampleCounter: UInt64 = 0
    
    public init(
        visualScanner: any BilateralFootScannerServiceProtocol,
        cameraPPG: any CameraPPGServiceProtocol,
        dspEngine: SignalProcessingEngine,
        classifier: VascularRiskClassifier,
        reportService: any ReportGenerationServiceProtocol
    ) {
        self.visualScanner = visualScanner
        self.cameraPPG = cameraPPG
        self.dspEngine = dspEngine
        self.classifier = classifier
        self.reportService = reportService
        bindCameraStreams()
    }
    
    public convenience init(
        visualScanner: (any BilateralFootScannerServiceProtocol)? = nil,
        cameraPPG: (any CameraPPGServiceProtocol)? = nil,
        dspEngine: SignalProcessingEngine? = nil,
        classifier: VascularRiskClassifier? = nil,
        reportService: (any ReportGenerationServiceProtocol)? = nil
    ) {
        self.init(
            visualScanner: visualScanner ?? BilateralFootScannerService(),
            cameraPPG: cameraPPG ?? CameraPPGService(),
            dspEngine: dspEngine ?? SignalProcessingEngine(sampleRate: 60.0),
            classifier: classifier ?? VascularRiskClassifier(),
            reportService: reportService ?? ReportGenerationService()
        )
    }
    
    // MARK: - Camera Stream Bindings
    
    private func bindCameraStreams() {
        cameraPPG.contactStateSubject
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.currentContactState = state
            }
            .store(in: &cancellables)
            
        cameraPPG.signalQualitySubject
            .throttle(for: .milliseconds(250), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] sqi in
                guard let self = self else { return }
                self.currentSQI = sqi
                if self.isRecordingPPG {
                    if self.currentStep == .step2FingerPPG {
                        self.fingerSQISamples.append(sqi)
                    } else if self.currentStep == .step3ToePPG {
                        self.toeSQISamples.append(sqi)
                    }
                }
            }
            .store(in: &cancellables)
            
        cameraPPG.sampleSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] point in
                guard let self = self, self.isRecordingPPG else { return }
                
                // Store raw sample in clinical buffer (full 60 FPS)
                if self.currentStep == .step2FingerPPG {
                    self.fingerRawSamples.append(point.rawGreen)
                } else if self.currentStep == .step3ToePPG {
                    self.toeRawSamples.append(point.rawGreen)
                }
                
                // Throttle chart rendering to ~7-8 FPS (every 8th sample) with an 80-point rolling window
                self.sampleCounter += 1
                if self.sampleCounter % 8 == 0 {
                    self.liveWaveformPoints.append(point)
                    if self.liveWaveformPoints.count > 80 {
                        self.liveWaveformPoints.removeFirst()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Step 1: Visual Photo Analysis
    
    public func processFootPhoto(_ image: UIImage) async {
        isProcessing = true
        errorMessage = nil
        capturedFootImage = image
        
        do {
            let result = try await visualScanner.analyzeBilateralDorsalFeet(image: image)
            self.visualResult = result
            self.isProcessing = false
            self.currentStep = .step2FingerPPG
            triggerHapticFeedback(.success)
        } catch {
            self.isProcessing = false
            self.errorMessage = error.localizedDescription
            triggerHapticFeedback(.error)
        }
    }
    
    // MARK: - Step 2 & 3: PPG Scan Workflow
    
    public func startCurrentPPGScan() async {
        liveWaveformPoints.removeAll()
        scanSecondsRemaining = 30
        isRecordingPPG = true
        errorMessage = nil
        sampleCounter = 0
        
        if currentStep == .step2FingerPPG {
            fingerRawSamples.removeAll()
            fingerSQISamples.removeAll()
        } else if currentStep == .step3ToePPG {
            toeRawSamples.removeAll()
            toeSQISamples.removeAll()
        }
        
        startScanTimer() // Start countdown immediately on MainActor
        
        // Launch camera hardware initialization in an independent Task so UI timer never freezes
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.cameraPPG.startCapture()
            } catch {
                await MainActor.run {
                    self.stopPPGScanEarly()
                    self.errorMessage = error.localizedDescription
                    self.triggerHapticFeedback(.error)
                }
            }
        }
    }
    
    private func startScanTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            while self.scanSecondsRemaining > 0 && self.isRecordingPPG {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled, self.isRecordingPPG else { break }
                self.scanSecondsRemaining -= 1
            }
            if self.isRecordingPPG && self.scanSecondsRemaining == 0 {
                await self.finishCurrentPPGScan()
            }
        }
    }
    
    public func stopPPGScanEarly() {
        timerTask?.cancel()
        cameraPPG.stopCapture()
        isRecordingPPG = false
    }
    
    private func finishCurrentPPGScan() async {
        stopPPGScanEarly()
        triggerHapticFeedback(.success)
        
        if currentStep == .step2FingerPPG {
            // Filter and extract Finger metrics
            fingerFilteredSamples = dspEngine.filterSignal(fingerRawSamples)
            let avgSQI = fingerSQISamples.isEmpty ? currentSQI : (fingerSQISamples.reduce(0.0, +) / Double(fingerSQISamples.count))
            fingerMorphometry = dspEngine.extractMorphometry(
                filteredSignal: fingerFilteredSamples,
                site: .finger,
                avgSQI: avgSQI
            )
            // Advance to Toe Scan
            currentStep = .step3ToePPG
        } else if currentStep == .step3ToePPG {
            // Filter and extract Toe metrics
            toeFilteredSamples = dspEngine.filterSignal(toeRawSamples)
            let avgSQI = toeSQISamples.isEmpty ? currentSQI : (toeSQISamples.reduce(0.0, +) / Double(toeSQISamples.count))
            toeMorphometry = dspEngine.extractMorphometry(
                filteredSignal: toeFilteredSamples,
                site: .toe,
                avgSQI: avgSQI
            )
            // Finalize overall diagnosis and generate report
            finalizeScreeningAssessment()
            currentStep = .step4Dashboard
        }
    }
    
    // MARK: - Step 4: Classification & Report Generation
    
    public func finalizeScreeningAssessment() {
        guard let vis = visualResult,
              let finger = fingerMorphometry,
              let toe = toeMorphometry else {
            return
        }
        
        let report = classifier.evaluateVascularRisk(
            visualResult: vis,
            fingerWave: finger,
            toeWave: toe,
            patientName: patientName,
            patientAge: patientAge
        )
        self.finalReport = report
        
        // ReportGenerationService is @MainActor, invoke directly
        let pdfData = reportService.generatePDFReport(
            report: report,
            footImage: capturedFootImage,
            fingerWaveformSamples: fingerFilteredSamples,
            toeWaveformSamples: toeFilteredSamples
        )
        self.generatedPDFData = pdfData
    }
    
    public func restartWorkflow() {
        stopPPGScanEarly()
        capturedFootImage = nil
        visualResult = nil
        fingerRawSamples.removeAll()
        fingerFilteredSamples.removeAll()
        fingerSQISamples.removeAll()
        fingerMorphometry = nil
        toeRawSamples.removeAll()
        toeFilteredSamples.removeAll()
        toeSQISamples.removeAll()
        toeMorphometry = nil
        finalReport = nil
        generatedPDFData = nil
        currentStep = .step1VisualPhoto
    }
    
    private func triggerHapticFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

// MARK: - SwiftUI Preview Helper

#if DEBUG
extension ScreeningWorkflowViewModel {
    public static func preview(
        step: ScreeningStep = .step1VisualPhoto,
        isProcessing: Bool = false,
        report: ComprehensivePADReport? = nil,
        isRecordingPPG: Bool = false,
        contactState: CameraContactState = .optimal,
        errorMessage: String? = nil
    ) -> ScreeningWorkflowViewModel {
        let vm = ScreeningWorkflowViewModel()
        vm.currentStep = step
        vm.isProcessing = isProcessing
        vm.finalReport = report
        vm.isRecordingPPG = isRecordingPPG
        vm.currentContactState = contactState
        vm.errorMessage = errorMessage
        if isRecordingPPG {
            vm.scanSecondsRemaining = 18
            vm.liveWaveformPoints = (0..<50).map { i in
                PPGDataPoint(
                    timestamp: Double(i) * 0.05,
                    filteredGreen: Float(sin(Double(i) * 0.4) * 40.0 + 100.0),
                    rawGreen: Float(sin(Double(i) * 0.4) * 40.0 + 100.0),
                    rawRed: 200.0
                )
            }
        }
        return vm
    }
}
#endif

