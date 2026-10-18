import SwiftUI
import PhotosUI
import UIKit

// MARK: - Step 1: Bilateral Foot Photo Scan View

public struct VisualPhotoScanView: View {
    @Bindable public var viewModel: ScreeningWorkflowViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isShowingCameraSheet = false
    @Environment(\.appLanguage) private var appLanguage
    
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
            
            // Dual Action Buttons: Camera Capture & Photo Library (> 56pt touch target)
            actionButtons
        }
        .fullScreenCover(isPresented: $isShowingCameraSheet) {
            CameraCaptureView { capturedImage in
                Task {
                    await viewModel.processFootPhoto(capturedImage)
                }
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Subviews
    
    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(HemosightStrings.visualInspectionTitle(for: appLanguage))
                    .appFont(size: appLanguage == .thai ? 17 : 18, weight: .bold)
            } icon: {
                Image(systemName: "camera.viewfinder")
                    .font(.title3)
            }
            .foregroundStyle(.blue)
            .toneMarkSafePadding(.bottom, 2)
            
            Text(HemosightStrings.visualInspectionDescription(for: appLanguage))
                .appFont(size: appLanguage == .thai ? 14 : 15, weight: .regular)
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
                    .accessibilityLabel(appLanguage == .thai ? "ภาพถ่ายหลังเท้าที่เลือก" : "Captured foot photo")
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "shoe.2.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue.opacity(0.4))
                        .accessibilityHidden(true)
                    
                    Text(HemosightStrings.visualPlacementTitle(for: appLanguage))
                        .appFont(size: appLanguage == .thai ? 16 : 17, weight: .bold)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text(HemosightStrings.visualPlacementSubtitle(for: appLanguage))
                        .appFont(size: appLanguage == .thai ? 13 : 14, weight: .regular)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
            }
            
            if viewModel.isProcessing {
                ProgressView {
                    Text(HemosightStrings.visualAnalyzing(for: appLanguage))
                        .appFont(size: 14, weight: .medium)
                        .padding(.top, 4)
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .clipShape(.rect(cornerRadius: 12))
                .accessibilityLabel(HemosightStrings.visualAnalyzing(for: appLanguage))
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
                .appFont(size: 14, weight: .medium)
                .foregroundStyle(.red)
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Primary Action: Live Camera Capture (> 56pt height)
            Button {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    isShowingCameraSheet = true
                } else {
                    viewModel.errorMessage = HemosightStrings.cameraUnavailableError(for: appLanguage)
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                        .font(.title3)
                    Text(HemosightStrings.visualCameraButton(for: appLanguage))
                        .appFont(size: appLanguage == .thai ? 16 : 17, weight: .bold)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: 14))
            }
            .accessibilityLabel(HemosightStrings.visualCameraButton(for: appLanguage))
            
            // Secondary Action: Photo Library Picker (> 56pt height)
            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3)
                    Text(HemosightStrings.visualLibraryButton(for: appLanguage))
                        .appFont(size: appLanguage == .thai ? 16 : 17, weight: .semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .foregroundStyle(Color.blue)
                .clipShape(.rect(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
                )
            }
            .accessibilityLabel(HemosightStrings.visualLibraryButton(for: appLanguage))
            .accessibilityHint(HemosightStrings.visualPickButtonHint(for: appLanguage))
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await viewModel.processFootPhoto(image)
                    } else {
                        viewModel.errorMessage = HemosightStrings.visualLoadError(for: appLanguage)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }
}

// MARK: - Previews

#Preview("Thai Step 1 - Initial State") {
    VisualPhotoScanView(viewModel: .preview(step: .step1VisualPhoto, language: .thai))
        .environment(\.appLanguage, .thai)
}

#Preview("Thai Step 1 - Processing State") {
    VisualPhotoScanView(viewModel: .preview(step: .step1VisualPhoto, isProcessing: true, language: .thai))
        .environment(\.appLanguage, .thai)
}

#Preview("English Step 1 - Initial State") {
    VisualPhotoScanView(viewModel: .preview(step: .step1VisualPhoto, language: .english))
        .environment(\.appLanguage, .english)
}
