import SwiftUI

struct NowPlayingView: View {
    let track: Track?

    var body: some View {
        VStack(spacing: 16) {
            AlbumArtView(artworkData: track?.artworkData, size: 200)

            if let track = track {
                VStack(spacing: 4) {
                    Text(track.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(track.artist)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if let album = track.album {
                        HStack(spacing: 4) {
                            Text(album)
                            if let year = track.releaseYear {
                                Text("(\(String(year)))")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                    }

                    ConfidenceIndicator(confidence: track.confidence)
                        .padding(.top, 4)
                }
            } else {
                VStack(spacing: 4) {
                    Text("No Track")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Start listening to identify music")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: track?.id)
    }
}
