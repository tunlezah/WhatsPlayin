import SwiftUI

struct StatusIndicator: View {
    let state: AppState
    let cooldownRemaining: TimeInterval
    let nextDetection: TimeInterval

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .overlay {
                    if isPulsing {
                        Circle()
                            .stroke(statusColor, lineWidth: 2)
                            .scaleEffect(1.5)
                            .opacity(0)
                            .animation(
                                .easeOut(duration: 1).repeatForever(autoreverses: false),
                                value: isPulsing
                            )
                    }
                }

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private var isPulsing: Bool {
        switch state {
        case .listening, .processing: return true
        default: return false
        }
    }

    private var statusColor: Color {
        switch state {
        case .idle: return Theme.idle
        case .listening: return Theme.listening
        case .processing: return Theme.processing
        case .identified: return Theme.identified
        case .coolingDown: return Theme.coolingDown
        case .error: return Theme.error
        }
    }

    private var statusText: String {
        switch state {
        case .coolingDown:
            return "Cooling down (\(Int(cooldownRemaining))s)"
        case .listening where nextDetection > 0:
            return "Listening… (next scan: \(Int(nextDetection))s)"
        default:
            return state.statusText
        }
    }
}
