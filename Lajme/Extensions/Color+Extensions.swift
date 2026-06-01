import SwiftUI
import UIKit

extension Color {
    /// App background: soft off-white in light mode, systemBackground (black) in dark mode
    static let appBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.systemBackground
            : UIColor(red: 0xFB / 255.0, green: 0xFA / 255.0, blue: 0xF7 / 255.0, alpha: 1.0)
    })
}
