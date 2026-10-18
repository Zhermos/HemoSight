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
    /// When language is `.thai`, uses Apple's official Thai web and branding typeface: "Sukhumvit Set" (SukhumvitSet).
    /// When language is `.english`, uses the standard iOS `.system(size:weight:design:)`.
    public func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch self {
        case .thai:
            let fontName = thaiFontName(for: weight)
            if UIFont(name: fontName, size: size) != nil {
                return .custom(fontName, size: size)
            }
            return .system(size: size, weight: weight)
        case .english:
            return .system(size: size, weight: weight)
        }
    }
    
    /// Returns the appropriate UIKit UIFont for graphics and PDF rendering.
    public func uiFont(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        switch self {
        case .thai:
            let fontName = thaiUIFontName(for: weight)
            if let customFont = UIFont(name: fontName, size: size) {
                return customFont
            }
            return UIFont.systemFont(ofSize: size, weight: weight)
        case .english:
            return UIFont.systemFont(ofSize: size, weight: weight)
        }
    }
    
    private func thaiFontName(for weight: Font.Weight) -> String {
        switch weight {
        case .bold, .heavy, .black:
            return "SukhumvitSet-Bold"
        case .semibold:
            return "SukhumvitSet-SemiBold"
        case .medium:
            return "SukhumvitSet-Medium"
        case .light, .thin, .ultraLight:
            return "SukhumvitSet-Light"
        default:
            return "SukhumvitSet-Text"
        }
    }
    
    private func thaiUIFontName(for weight: UIFont.Weight) -> String {
        switch weight {
        case .bold, .heavy, .black:
            return "SukhumvitSet-Bold"
        case .semibold:
            return "SukhumvitSet-SemiBold"
        case .medium:
            return "SukhumvitSet-Medium"
        case .light, .thin, .ultraLight:
            return "SukhumvitSet-Light"
        default:
            return "SukhumvitSet-Text"
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
