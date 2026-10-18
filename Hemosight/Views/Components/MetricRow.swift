import SwiftUI

// MARK: - Clinical Metric Row Component

public struct MetricRow: View {
    public let label: String
    public let value: String
    public let status: String
    public let isWarning: Bool
    @Environment(\.appLanguage) private var appLanguage
    
    public init(
        label: String,
        value: String,
        status: String,
        isWarning: Bool
    ) {
        self.label = label
        self.value = value
        self.status = status
        self.isWarning = isWarning
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .appFont(size: appLanguage == .thai ? 13 : 14, weight: .regular)
                    .foregroundStyle(.secondary)
                    .toneMarkSafePadding(.bottom, 1)
                
                Text(value)
                    .appFont(size: appLanguage == .thai ? 18 : 20, weight: .bold)
                    .foregroundStyle(.primary)
            }
            .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 8)
            
            Text(status)
                .appFont(size: appLanguage == .thai ? 12 : 11, weight: .semibold)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isWarning ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                .foregroundStyle(isWarning ? Color.red : Color.green)
                .clipShape(Capsule())
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value), status: \(status)")
    }
}

// MARK: - Previews

#Preview("Thai Metric Row - Normal") {
    VStack(spacing: 12) {
        MetricRow(
            label: "เวลาเพิ่มขึ้นของคลื่นชีพจรนิ้วเท้า (SRT)",
            value: "115 ms",
            status: "คลื่นชีพจรคมชัด (Crisp Upstroke)",
            isWarning: false
        )
        
        MetricRow(
            label: "ดัชนีชีพจรปลายเท้าเทียบมือ (PRT Ratio)",
            value: "0.68",
            status: "การไหลเวียนเลือดดีเยี่ยม (Robust Perfusion)",
            isWarning: false
        )
    }
    .environment(\.appLanguage, .thai)
    .padding()
    .background(Color(uiColor: .secondarySystemGroupedBackground))
    .clipShape(.rect(cornerRadius: 12))
    .padding()
}

#Preview("Thai Metric Row - Warning") {
    VStack(spacing: 12) {
        MetricRow(
            label: "ความไม่สมมาตรของสีผิวเท้า (Color Disparity)",
            value: "5.82",
            status: "พบความไม่สมมาตร (Disparity Flagged)",
            isWarning: true
        )
        
        MetricRow(
            label: "เวลาเพิ่มขึ้นของคลื่นชีพจรนิ้วเท้า (SRT)",
            value: "210 ms",
            status: "คลื่นชีพจรหน่วง / ช้าลง (Prolonged / Damped)",
            isWarning: true
        )
    }
    .environment(\.appLanguage, .thai)
    .padding()
    .background(Color(uiColor: .secondarySystemGroupedBackground))
    .clipShape(.rect(cornerRadius: 12))
    .padding()
}

#Preview("English Metric Row - Normal") {
    VStack(spacing: 12) {
        MetricRow(
            label: "Toe Systolic Rise Time (SRT)",
            value: "115 ms",
            status: "Crisp Upstroke",
            isWarning: false
        )
    }
    .environment(\.appLanguage, .english)
    .padding()
    .background(Color(uiColor: .secondarySystemGroupedBackground))
    .clipShape(.rect(cornerRadius: 12))
    .padding()
}
