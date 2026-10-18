import Testing
import UIKit
@testable import Hemosight

@Suite("Bilateral Foot Scanner Service Tests")
struct BilateralFootScannerServiceTests {
    
    let scanner = BilateralFootScannerService()
    
    @Test("Image without valid underlying CGImage throws invalidImageData error")
    func testInvalidImageDataThrows() async {
        // Given: UIImage created without backing CGImage (empty image)
        let emptyImage = UIImage()
        
        // When & Then
        await #expect(throws: VisualInspectionError.invalidImageData) {
            _ = try await scanner.analyzeBilateralDorsalFeet(image: emptyImage)
        }
    }
    
    @Test(
        "VisualInspectionError provides meaningful clinical descriptions",
        arguments: [
            (VisualInspectionError.invalidImageData, "Unable to process"),
            (VisualInspectionError.feetSegmentationFailed, "delineate left and right"),
            (VisualInspectionError.insufficientContoursDetected, "Insufficient dorsal skin"),
            (VisualInspectionError.illuminationInadequate, "Lighting is too dark")
        ]
    )
    func testVisualInspectionErrorDescriptions(error: VisualInspectionError, expectedSubstring: String) {
        // Given & When
        let description = error.errorDescription
        
        // Then
        #expect(description?.contains(expectedSubstring) == true)
    }
    
    @Test("BilateralFootScannerSpyingStub captures input image and returns configured result")
    func testSpyingStubCapturesInvocation() async throws {
        // Given
        let expectedResult = VisualIschemiaResult.fixture(deltaE: 3.5)
        let stub = BilateralFootScannerSpyingStub(resultToReturn: expectedResult)
        let inputImage = UIImage()
        
        // When
        let result = try await stub.analyzeBilateralDorsalFeet(image: inputImage)
        
        // Then
        #expect(stub.capturedImages.count == 1)
        #expect(result.deltaE == 3.5)
    }
}
