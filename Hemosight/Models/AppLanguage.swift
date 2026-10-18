import Foundation
import SwiftUI
import UIKit

/// Supported interface languages for Hemosight.
public enum AppLanguage: String, CaseIterable, Identifiable, Sendable, Codable {
    case english = "en"
    case thai = "th"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .english: return "English"
        case .thai: return "ภาษาไทย"
        }
    }
    
    public var flagEmoji: String {
        switch self {
        case .english: return "🇺🇸"
        case .thai: return "🇹🇭"
        }
    }
    
    public var shortLabel: String {
        switch self {
        case .english: return "EN"
        case .thai: return "TH"
        }
    }
    
    public var toggleButtonLabel: String {
        switch self {
        case .english: return "🇺🇸 EN | 🇹🇭 TH"
        case .thai: return "🇹🇭 TH | 🇺🇸 EN"
        }
    }
    
    /// Returns the appropriate SwiftUI Font based on the active language.
    /// When language is `.thai`, uses iOS built-in legible Thai typography: "Thonburi" (or "Thonburi-Bold" for bold text).
    /// When language is `.english`, uses the standard iOS `.system(size:weight:design:)`.
    public func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch self {
        case .thai:
            let isBold = (weight == .bold || weight == .heavy || weight == .black || weight == .semibold)
            let fontName = isBold ? "Thonburi-Bold" : "Thonburi"
            return .custom(fontName, size: size)
        case .english:
            return .system(size: size, weight: weight)
        }
    }
    
    /// Returns the appropriate UIKit UIFont for graphics and PDF rendering.
    public func uiFont(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        switch self {
        case .thai:
            let isBold = (weight == .bold || weight == .heavy || weight == .black || weight == .semibold)
            let fontName = isBold ? "Thonburi-Bold" : "Thonburi"
            if let customFont = UIFont(name: fontName, size: size) {
                return customFont
            }
            return UIFont.systemFont(ofSize: size, weight: weight)
        case .english:
            return UIFont.systemFont(ofSize: size, weight: weight)
        }
    }
}

// MARK: - SwiftUI Environment Key for AppLanguage

private struct AppLanguageKey: EnvironmentKey {
    static let defaultValue: AppLanguage = .english
}

extension EnvironmentValues {
    public var appLanguage: AppLanguage {
        get { self[AppLanguageKey.self] }
        set { self[AppLanguageKey.self] = newValue }
    }
}
