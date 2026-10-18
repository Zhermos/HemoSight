import SwiftUI
import PhotosUI

// MARK: - Step 1: Bilateral Foot Photo Scan View

public struct VisualPhotoScanView: View {
    @Bindable public var viewModel: ScreeningWorkflowViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    public init(viewModel: ScreeningWorkflowViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Instructions Card
            instructionsCard
            
            // Silhouette Placement Overlay Box
            photoPlacementBox
            
            // Error Message Banner (if present)
            if let error = viewModel.errorMessage {
                errorMessageBanner(error)
            }
            
            Spacer()
            
            // PhotosPicker Button (> 56pt touch target for accessibility)
            photoPickerButton
        }
    }
    
    // MARK: - Subviews
    
    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Bilateral Dorsal Foot Inspection", systemImage: "camera.viewfinder")
                .font(.title3.weight(.bold))
                .foregroundStyle(.blue)
            
            Text("Position both feet side-by-side under clear, even lighting. Our computer vision engine analyzes skin color symmetry (CIE L*a*b*) to detect unilateral blanching or ischemic pallor.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
    }
    
    private var photoPlacementBox: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [8]))
                .foregroundStyle(Color.blue.opacity(0.6))
                .background(Color.blue.opacity(0.04))
            
            if let image = viewModel.capturedFootImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(.rect(cornerRadius: 12))
                    .padding(8)
                    .accessibilityLabel("Captured foot photo")
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "shoe.2.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.blue.opacity(0.4))
                        .accessibilityHidden(true)
                    
                    Text("Align Left and Right Feet Here")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Ensure dorsal skin (top of feet) is fully uncovered")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
            }
            
            if viewModel.isProcessing {
                ProgressView("Analyzing bilateral chromaticity...")
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(.rect(cornerRadius: 10))
                    .accessibilityLabel("Analyzing bilateral chromaticity")
            }
        }
        .frame(height: 280)
        .padding(.horizontal)
    }
    
    private func errorMessageBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.callout)
                .foregroundStyle(.red)
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
    }
    
    private var photoPickerButton: some View {
        PhotosPicker(
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            HStack {
                Image(systemName: "photo.badge.plus")
                Text("Select Foot Photo from Library")
                    .font(.title3.weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 14))
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
        .accessibilityLabel("Select Foot Photo from Library")
        .accessibilityHint("Opens photo library to pick dorsal foot inspection image")
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await viewModel.processFootPhoto(image)
                } else {
                    viewModel.errorMessage = "Failed to load selected photo."
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Step 1 - Initial State") {
    VisualPhotoScanView(viewModel: .preview(step: .step1VisualPhoto))
}

#Preview("Step 1 - Processing State") {
    VisualPhotoScanView(viewModel: .preview(step: .step1VisualPhoto, isProcessing: true))
}

#Preview("Step 1 - Error State") {
    VisualPhotoScanView(
        viewModel: .preview(
            step: .step1VisualPhoto,
            errorMessage: "Unable to segment left and right foot regions. Please ensure even lighting."
        )
    )
}
