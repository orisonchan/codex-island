import Foundation

/// Formats a raw token count into a compact coefficient + suffix pair
/// ("12.4" + "M") for hero displays. Shared by the Cost page (`CostTile`)
/// and the Usage page (`ChartTile`) so both use identical bands/suffixes.
///
/// Bands mirror ccusage: plain int under 1k, tenths-of-k under 10k,
/// whole-k under 1M, tenths-of-M under 1B, tenths-of-B beyond. "tok"
/// suffix under 1k so a tiny count still reads as tokens, not a bare
/// number.
enum TokenFormat {
    static func value(_ tokens: Int) -> String {
        let v = Double(tokens)
        if tokens < 1_000 { return "\(tokens)" }
        if tokens < 10_000 { return String(format: "%.1f", v / 1_000) }
        if tokens < 1_000_000 { return String(format: "%.0f", v / 1_000) }
        if tokens < 1_000_000_000 { return String(format: "%.1f", v / 1_000_000) }
        return String(format: "%.1f", v / 1_000_000_000)
    }

    static func unit(_ tokens: Int) -> String {
        if tokens < 1_000 { return "tok" }
        if tokens < 1_000_000 { return "k" }
        if tokens < 1_000_000_000 { return "M" }
        return "B"
    }
}
