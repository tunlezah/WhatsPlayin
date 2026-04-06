import SwiftUI

struct ConfidenceIndicator: View {
    let confidence: Double

    private var color: Color {
        switch confidence {
        case 0.8...1.0: return Theme.cyan
        case 0.6..<0.8: return Theme.purple
        default: return Theme.amber
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            ProgressView(value: confidence)
                .progressViewStyle(.linear)
                .tint(color)
                .frame(width: 60)

            Text("\(Int(confidence * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}
