import SwiftUI

/// Country options and helpers used by the toolbar country picker.
/// Previously this file held a full pill-row view; we moved to a minimal
/// toolbar chevron + confirmation dialog to save vertical space.
enum CountryFilter {
    /// Country options — `code == nil` means "all countries".
    /// Labels are in Albanian to match the rest of the UI.
    /// Diaspora uses a globe emoji since it spans multiple countries.
    static let options: [(code: String?, label: String, flag: String)] = [
        (nil, "Të gjitha", ""),
        ("XK", "Kosovë", "🇽🇰"),
        ("AL", "Shqipëri", "🇦🇱"),
        ("MK", "Maqedoni", "🇲🇰"),
        ("CH", "Diaspora", "🌍"),
    ]

    /// Human-readable label for a given country code, defaulting to "Të gjitha".
    static func label(for code: String?) -> String {
        options.first(where: { $0.code == code })?.label ?? "Të gjitha"
    }

    /// Label plus flag, e.g. "Kosovë 🇽🇰". For "Të gjitha" (all), no flag.
    static func labelWithFlag(for code: String?) -> String {
        let option = options.first(where: { $0.code == code }) ?? options[0]
        return option.flag.isEmpty ? option.label : "\(option.label) \(option.flag)"
    }
}
