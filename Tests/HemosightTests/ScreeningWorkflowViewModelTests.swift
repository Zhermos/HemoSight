import Testing
import UIKit
import Combine
@testable import Hemosight

@Suite("Screening Workflow ViewModel Tests")
@MainActor
struct ScreeningWorkflowViewModelTests {
    
    // MARK: - Initial State
    
    @Test("ViewModel initializes at Step 1 with clean state")
    func testInitialState() {
        // Given
        let scannerStub = BilateralFootScannerSpyingStub()
        let cameraStub = CameraPPGServiceSpyingStub()
        let reportStub = ReportGenerationServiceSpyingStub()
        
        // When
        let viewModel = ScreeningWorkflowViewModel(
            visualScanner: scannerStub,
            cameraPPG: cameraStub,
            reportService: reportStub
        )
        
        // Then
        #expect(viewModel.currentStep == .step1VisualPhoto)
        #expect(!viewModel.isProcessing)
        #expect(!viewModel.isRecordingPPG)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.capturedFootImage == nil)
        #expect(viewModel.visualResult == nil)
        #expect(viewModel.finalReport == nil)
    }
    
    // MARK: - Step 1: Foot Photo Processing
    
    @Test("Successful foot photo processing advances step to Finger PPG")
    func testProcessFootPhotoSuccess() async {
        // Given
        let expectedResult = VisualIschemiaResult.fixture(deltaE: 2.1)
        let scannerStub = BilateralFootScannerSpyingStub(resultToReturn: expectedResult)
        let viewModel = ScreeningWorkflowViewModel(visualScanner: scannerStub)
        let testImage = UIImage()
        
        // When
        await viewModel.processFootPhoto(testImage)
        
        // Then
        #expect(scannerStub.capturedImages.count == 1)
        #expect(viewModel.visualResult?.deltaE == 2.1)
        #expect(viewModel.currentStep == .step2FingerPPG)
        #expect(!viewModel.isProcessing)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("Failed foot photo processing remains at Step 1 with error message")
    func testProcessFootPhotoFailure() async {
        // Given
        let error = VisualInspectionError.feetSegmentationFailed
        let scannerStub = BilateralFootScannerSpyingStub(errorToThrow: error)
        let viewModel = ScreeningWorkflowViewModel(visualScanner: scannerStub)
        
        // When
        await viewModel.processFootPhoto(UIImage())
        
        // Then
        #expect(viewModel.currentStep == .step1VisualPhoto)
        #expect(!viewModel.isProcessing)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.visualResult == nil)
    }
    
    // MARK: - Step 2 & 3: PPG Stream & Buffer Management
    
    @Test("Live samples are captured and bounded by the 240-sample rolling window")
    func testLiveWaveformRollingBuffer() async {
        // Given
        let cameraStub = CameraPPGServiceSpyingStub()
        let viewModel = ScreeningWorkflowViewModel(cameraPPG: cameraStub)
        
        viewModel.currentStep = .step2FingerPPG
        viewModel.isRecordingPPG = true
        
        // When: Emitting 260 samples (more than the 240 maximum rolling window)
        for i in 0..<260 {
            cameraStub.emitSample(
                green: Float(i),
                red: 200.0,
                timestamp: Double(i) * 0.016,
                sqi: 0.95
            )
        }
        
        // Allow Combine sink to process on main queue
        await Task.yield()
        
        // Then
        #expect(viewModel.liveWaveformPoints.count == 240)
        #expect(viewModel.fingerRawSamples.count == 260)
        #expect(viewModel.currentSQI == 0.95)
    }
    
    @Test("Camera failure during start sets error state and aborts recording")
    func testCameraFailureOnStart() async {
        // Given
        let cameraStub = CameraPPGServiceSpyingStub(errorToThrowOnStart: CameraPPGError.cameraUnavailable)
        let viewModel = ScreeningWorkflowViewModel(cameraPPG: cameraStub)
        
        // When
        await viewModel.startCurrentPPGScan()
        
        // Then
        #expect(!viewModel.isRecordingPPG)
        #expect(viewModel.errorMessage != nil)
        #expect(cameraStub.startCaptureCallCount == 1)
    }
    
    // MARK: - Step 4: Finalize & PDF Generation
    
    @Test("Finalizing assessment evaluates risk and triggers PDF generation")
    func testFinalizeScreeningAssessment() async {
        // Given
        let expectedPdfData = Data([0x25, 0x50, 0x44, 0x46, 0x31]) // Custom mock PDF data
        let reportStub = ReportGenerationServiceSpyingStub(dataToReturn: expectedPdfData)
        let viewModel = ScreeningWorkflowViewModel(reportService: reportStub)
        
        viewModel.visualResult = .fixture()
        viewModel.fingerMorphometry = .fixture(site: .finger)
        viewModel.toeMorphometry = .fixture(site: .toe)
        
        // When
        await viewModel.finalizeScreeningAssessment()
        
        // Then
        #expect(viewModel.finalReport != nil)
        #expect(viewModel.generatedPDFData == expectedPdfData)
        #expect(reportStub.generatedReports.count == 1)
    }
    
    // MARK: - Restart Workflow
    
    @Test("Restart workflow cleans all state and returns to Step 1")
    func testRestartWorkflow() {
        // Given
        let cameraStub = CameraPPGServiceSpyingStub()
        let viewModel = ScreeningWorkflowViewModel(cameraPPG: cameraStub)
        
        viewModel.currentStep = .step3ToePPG
        viewModel.isRecordingPPG = true
        viewModel.visualResult = .fixture()
        viewModel.fingerRawSamples = [1.0, 2.0]
        viewModel.finalReport = .fixture()
        
        // When
        viewModel.restartWorkflow()
        
        // Then
        #expect(viewModel.currentStep == .step1VisualPhoto)
        #expect(!viewModel.isRecordingPPG)
        #expect(viewModel.visualResult == nil)
        #expect(viewModel.fingerRawSamples.isEmpty)
        #expect(viewModel.finalReport == nil)
        #expect(cameraStub.stopCaptureCallCount >= 1)
    }
}
