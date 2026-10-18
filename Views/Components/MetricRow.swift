import SwiftUI

// MARK: - Clinical Metric Row Component

public struct MetricRow: View {
    public let label: String
    public let value: String
    public let status: String
    public let isWarning: Bool
    
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
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3.weight(.bold))
            }
            Spacer()
            Text(status)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isWarning ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                .foregroundStyle(isWarning ? Color.red : Color.green)
                .clipShape(Capsule())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value), status: \(status)")
    }
}

// MARK: - Previews

#Preview("Metric Row - Normal") {
    VStack(spacing: 12) {
        MetricRow(
            label: "Toe Systolic Rise Time (SRT)",
            value: "115 ms",
            status: "Crisp Upstroke",
            isWarning: false
        )
        
        MetricRow(
            label: "Toe-to-Finger Amplitude Ratio",
            value: "0.68",
            status: "Robust Perfusion",
            isWarning: false
        )
    }
    .padding()
    .background(Color(uiColor: .secondarySystemGroupedBackground))
    .clipShape(.rect(cornerRadius: 12))
    .padding()
}

#Preview("Metric Row - Warning") {
    VStack(spacing: 12) {
        MetricRow(
            label: "Bilateral Skin Color Disparity (ΔE)",
            value: "5.82",
            status: "Disparity Flagged",
            isWarning: true
        )
        
        MetricRow(
            label: "Toe Systolic Rise Time (SRT)",
            value: "210 ms",
            status: "Prolonged / Damped",
            isWarning: true
        )
    }
    .padding()
    .background(Color(uiColor: .secondarySystemGroupedBackground))
    .clipShape(.rect(cornerRadius: 12))
    .padding()
}
