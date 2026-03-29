import SwiftUI

struct HistoryView: View {
    let tracks: [Track]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("History")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.bottom, 6)

            if tracks.isEmpty {
                Text("No tracks detected yet")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 1) {
                    ForEach(tracks) { track in
                        HistoryRow(track: track)
                    }
                }
            }
        }
    }
}

struct HistoryRow: View {
    let track: Track

    var body: some View {
        HStack(spacing: 10) {
            AlbumArtView(artworkData: track.artworkData, size: 36)

            VStack(alignment: .leading, spacing: 1) {
                Text(track.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(track.artist)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(track.detectedAt, style: .time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial.opacity(0.5))
    }
}
