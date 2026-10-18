import SwiftUI
import UIKit

// MARK: - Native Camera Photo Capture Sheet (UIImagePickerController)

public struct CameraCaptureView: UIViewControllerRepresentable {
    public let onPhotoCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    public init(onPhotoCaptured: @escaping (UIImage) -> Void) {
        self.onPhotoCaptured = onPhotoCaptured
    }
    
    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
        } else {
            // Simulator or hardware restriction fallback
            picker.sourceType = .photoLibrary
        }
        
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: CameraCaptureView
        
        init(_ parent: CameraCaptureView) {
            self.parent = parent
        }
        
        public func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            // Trigger capture haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            
            if let image = info[.originalImage] as? UIImage {
                parent.onPhotoCaptured(image)
            }
            
            picker.dismiss(animated: true)
            parent.dismiss()
        }
        
        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            parent.dismiss()
        }
    }
}
