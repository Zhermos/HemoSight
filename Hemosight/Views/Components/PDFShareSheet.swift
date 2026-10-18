import SwiftUI
import UIKit

// MARK: - Identifiable PDF Share Item (for item-driven .sheet(item:))

public struct ShareablePDFItem: Identifiable, Sendable {
    public let id: UUID
    public let data: Data
    
    public init(id: UUID = UUID(), data: Data) {
        self.id = id
        self.data = data
    }
}

// MARK: - UIKit UIActivityViewController Bridge

public struct PDFShareSheet: UIViewControllerRepresentable {
    public let activityItems: [Any]
    
    public init(activityItems: [Any]) {
        self.activityItems = activityItems
    }
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
