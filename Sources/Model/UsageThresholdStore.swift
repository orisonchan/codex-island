import Foundation

/// User-configurable token-volume thresholds that define "100%" on the
/// Usage page. The Usage page shows absolute token usage (from local
/// session logs) as a fraction of these thresholds, so the existing
/// percentage-bound chart styles (ring/bar/stepped/numeric/spark) keep
/// working without a subscription quota: `value% = tokensUsed / threshold × 100`.
///
/// Defaults: 5h = 200M, 7d = 5000M (5B) tokens. Editable in Settings.
/// Clamped to a non-zero range so a direct UserDefaults edit can't produce
/// a divide-by-zero in the percent math.
@MainActor
final class UsageThresholdStore: ObservableObject {
    static let shared = UsageThresholdStore()

    private static let fiveHourKey = "MacIsland.usageThreshold5h"
    private static let sevenDayKey = "MacIsland.usageThreshold7d"

    /// 1M … 100B tokens. Lower bound > 0 avoids divide-by-zero; upper bound
    /// is a generous ceiling for extreme users.
    static let range: ClosedRange<Int> = 1_000_000...100_000_000_000

    static let defaultFiveHour = 200_000_000      // 200M
    static let defaultSevenDay = 5_000_000_000    // 5B (5000M)

    @Published var fiveHour: Int {
        didSet { UserDefaults.standard.set(fiveHour, forKey: Self.fiveHourKey) }
    }

    @Published var sevenDay: Int {
        didSet { UserDefaults.standard.set(sevenDay, forKey: Self.sevenDayKey) }
    }

    private init() {
        self.fiveHour = Pref.int(key: Self.fiveHourKey, default: Self.defaultFiveHour, range: Self.range)
        self.sevenDay = Pref.int(key: Self.sevenDayKey, default: Self.defaultSevenDay, range: Self.range)
    }
}
