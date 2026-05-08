import Foundation

/// User preference for the ambient halo + loading sweep.
///
/// Default off: both the halo glow and the cobalt orbit run continuously.
/// With low-power mode on, both surfaces are gated on a "glow event"
/// predicate — they appear only while a fetch is in flight, the cursor is
/// hovering the island, or an alert is active. At rest the island goes
/// dark, saving the per-frame angular-gradient + blur work.
@MainActor
final class LowPowerModeStore: ObservableObject {
    static let shared = LowPowerModeStore()

    private static let key = "MacIsland.lowPowerMode"

    @Published var enabled: Bool {
        didSet { UserDefaults.standard.set(enabled, forKey: Self.key) }
    }

    private init() {
        // UserDefaults.bool returns false for missing keys, which matches our
        // intended default (off → continuous sweep).
        self.enabled = UserDefaults.standard.bool(forKey: Self.key)
    }
}
