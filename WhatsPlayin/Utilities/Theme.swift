import SwiftUI

/// App color theme derived from the icon: turntable on dark navy with cyan/purple waveform
enum Theme {
    // Primary brand colors from icon
    static let cyan = Color(red: 0.0, green: 0.83, blue: 1.0)           // #00D4FF — electric blue waveform
    static let purple = Color(red: 0.55, green: 0.36, blue: 0.96)       // #8B5CF6 — violet glow
    static let amber = Color(red: 0.83, green: 0.65, blue: 0.45)        // #D4A574 — warm turntable edge
    static let navy = Color(red: 0.04, green: 0.09, blue: 0.16)         // #0A1628 — deep background
    static let midnightBlue = Color(red: 0.08, green: 0.14, blue: 0.24) // #14243D — lighter navy

    // Semantic colors
    static let accent = cyan
    static let listening = cyan
    static let processing = purple
    static let identified = purple
    static let coolingDown = amber
    static let error = Color(red: 1.0, green: 0.35, blue: 0.35)         // Warm red
    static let idle = Color(red: 0.45, green: 0.50, blue: 0.58)         // Muted steel

    // Gradients
    static let backgroundGradient = LinearGradient(
        colors: [navy, midnightBlue, navy],
        startPoint: .top,
        endPoint: .bottom
    )

    static let headerGradient = LinearGradient(
        colors: [cyan, purple],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let waveformGradient = LinearGradient(
        colors: [cyan, purple],
        startPoint: .leading,
        endPoint: .trailing
    )
}
