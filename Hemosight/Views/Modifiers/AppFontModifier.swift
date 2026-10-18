import SwiftUI

// MARK: - Elderly-Accessible Thai & English Typography Modifier

public struct AppFontModifier: ViewModifier {
    public let size: CGFloat
    public let weight: Font.Weight
    public let overrideLanguage: AppLanguage?
    @Environment(\.appLanguage) private var envLanguage
    
    public init(
        size: CGFloat,
        weight: Font.Weight = .regular,
        overrideLanguage: AppLanguage? = nil
    ) {
        self.size = size
        self.weight = weight
        self.overrideLanguage = overrideLanguage
    }
    
    private var activeLanguage: AppLanguage {
        overrideLanguage ?? envLanguage
    }
    
    public func body(content: Content) -> some View {
        content
            .font(activeLanguage.font(size: size, weight: weight))
            // Thai tone marks (วรรณยุกต์) exist above and below the glyph body.
            // Extra line spacing prevents tone marks from clipping in multi-line labels and cards.
            .lineSpacing(activeLanguage == .thai ? 4.5 : 2.0)
    }
}

// MARK: - View Extension

extension View {
    /// Applies language-aware typography with full support for legible Thai glyphs (Thonburi) and tone-mark clearance.
    public func appFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        language: AppLanguage? = nil
    ) -> some View {
        modifier(AppFontModifier(size: size, weight: weight, overrideLanguage: language))
    }
    
    /// Adds vertical breathing room for Thai tone marks (วรรณยุกต์) in cards and banner titles.
    public func toneMarkSafePadding(_ edges: Edge.Set = .vertical, _ length: CGFloat = 2) -> some View {
        self.padding(edges, length)
    }
}

// MARK: - Previews

#Preview("Thai Typography - Thonburi Font") {
    VStack(alignment: .leading, spacing: 16) {
        Text("ขั้นตอนที่ 1: ถ่ายภาพหลังเท้าทั้งสองข้าง")
            .appFont(size: 20, weight: .bold, language: .thai)
        
        Text("คุณภาพสัญญาณดีเยี่ยม — กรุณาวางนิ่งๆ")
            .appFont(size: 16, weight: .regular, language: .thai)
            .foregroundStyle(.green)
        
        Text("ความเสี่ยงสูง (High Risk / Ischemia)")
            .appFont(size: 18, weight: .black, language: .thai)
            .foregroundStyle(.red)
        
        Text("แนะนำให้ปรึกษาแพทย์เฉพาะทางด้านโรคหลอดเลือดและหัวใจเพื่อรับการตรวจ ABI เพิ่มเติม")
            .appFont(size: 14, weight: .medium, language: .thai)
            .foregroundStyle(.secondary)
    }
    .padding()
}

#Preview("English Typography - System Font") {
    VStack(alignment: .leading, spacing: 16) {
        Text("Step 1: Bilateral Foot Photo")
            .appFont(size: 20, weight: .bold, language: .english)
        
        Text("Signal Quality Optimal — keep steady")
            .appFont(size: 16, weight: .regular, language: .english)
            .foregroundStyle(.green)
        
        Text("High Risk (Ischemic Pattern Detected)")
            .appFont(size: 18, weight: .black, language: .english)
            .foregroundStyle(.red)
    }
    .padding()
}
