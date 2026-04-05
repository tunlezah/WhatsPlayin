import SwiftUI

struct DebugView: View {
    @ObservedObject var audioService: AudioService
    @ObservedObject var recognitionService: RecognitionService
    let duplicateService: DuplicateDetectionService

    private let logger = AppLogger.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Debug")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.cyan)
                Spacer()
                Button("Clear") {
                    logger.clearDebugEntries()
                }
                .font(.caption2)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            // Audio levels
            VStack(alignment: .leading, spacing: 4) {
                Text("Audio Level")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                ProgressView(value: Double(audioService.currentLevel), total: 1.0)
                    .progressViewStyle(.linear)
                    .tint(audioService.isSilent ? Theme.idle : Theme.cyan)
            }

            // Buffer fill
            VStack(alignment: .leading, spacing: 4) {
                Text("Buffer: \(String(format: "%.1f", audioService.bufferDurationSeconds))s (\(Int(audioService.bufferFillPercent * 100))%)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                ProgressView(value: audioService.bufferFillPercent)
                    .progressViewStyle(.linear)
                    .tint(Theme.purple)
            }

            // Cooldown state
            HStack {
                Text("Cooldown:")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text(duplicateService.isInCooldown ? "\(Int(duplicateService.remainingCooldown))s" : "none")
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(duplicateService.isInCooldown ? Theme.amber : Theme.cyan)
            }

            // Log entries
            Divider()
                .overlay(Theme.midnightBlue)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(logger.debugEntries.suffix(50).reversed()) { entry in
                        HStack(alignment: .top, spacing: 4) {
                            Text(entry.timestamp, format: .dateTime.hour().minute().second())
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.tertiary)
                            Text("[\(entry.category.rawValue)]")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(Theme.cyan.opacity(0.6))
                            Text(entry.message)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .frame(maxHeight: 150)
        }
        .padding(10)
        .background(Theme.midnightBlue.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Theme.cyan.opacity(0.1), lineWidth: 1)
        )
    }
}
