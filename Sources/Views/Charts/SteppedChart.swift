import SwiftUI

struct SteppedChart: View {
    let value: Double      // 0-100 fill fraction of the token threshold
    let color: Color
    let label: String
    let sub: String
    let tokenText: String
    let tokenUnit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ChartHead(value: value, label: label, tokenText: tokenText, tokenUnit: tokenUnit)
            HStack(spacing: 2) {
                let segments = 30
                let filled = (value / 100) * Double(segments)
                ForEach(0..<segments, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Double(i) < floor(filled) ? color : .white.opacity(0.10))
                        .frame(maxWidth: .infinity)
                        .frame(height: 16)
                        // ~7ms stagger across 30 cells = ~210ms sweep when
                        // a new value arrives. Stays under the 300ms budget.
                        .animation(.strongEaseOut.delay(Double(i) * 0.007), value: value)
                }
            }
            ChartFoot(caption: sub)
        }
    }
}
