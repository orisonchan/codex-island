import SwiftUI

/// Shared head for the three "label + big number" charts (Bar, Stepped,
/// Spark). RingChart and NumericChart render their own custom heads.
struct ChartHead: View {
    let value: Double
    let label: String
    /// Token hero digit + suffix (e.g. "12.4" + "M"). `value` stays the
    /// 0-100 fill fraction for the geometry + urgency color; the digit
    /// itself is the truthful absolute token count.
    let tokenText: String
    let tokenUnit: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(Typography.label)
                .foregroundStyle(.white.opacity(0.55))
                .textCase(.lowercase)
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(tokenText)
                    .font(Typography.chartValue)
                    .foregroundStyle(UrgencyColor.value(value))
                    .numericTransition(value: value)
                    .animation(.strongEaseOut, value: value)
                Text(tokenUnit)
                    .font(Typography.label)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }
}

struct ChartFoot: View {
    let caption: String

    var body: some View {
        Text(caption)
            .font(Typography.caption)
            .foregroundStyle(.white.opacity(0.4))
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
