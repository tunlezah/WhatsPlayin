import SwiftUI

/// Full-screen Now Playing view designed for AirPlay display on Apple TV
struct AirPlayNowPlayingView: View {
    let currentTrack: Track?
    let recentTracks: [Track]

    @State private var animateGradient = false

    var body: some View {
        ZStack {
            // Animated gradient background
            backgroundGradient
                .ignoresSafeArea()

            VStack {
                Spacer()

                // Main album art
                AlbumArtView(artworkData: currentTrack?.artworkData, size: 400)
                    .padding(.bottom, 30)

                // Track info
                if let track = currentTrack {
                    VStack(spacing: 8) {
                        Text(track.title)
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .shadow(color: Theme.cyan.opacity(0.5), radius: 8)

                        Text(track.artist)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(1)
                            .shadow(radius: 2)

                        if let album = track.album {
                            Text(album)
                                .font(.system(size: 18))
                                .foregroundStyle(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "music.note")
                            .font(.system(size: 60))
                            .foregroundStyle(Theme.cyan.opacity(0.5))
                        Text("Waiting for music…")
                            .font(.system(size: 24))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Spacer()

                // History strip (last 3 tracks)
                if !recentTracks.isEmpty {
                    historyStrip
                        .padding(.bottom, 40)
                }
            }
            .padding(60)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Theme.navy,
                (currentTrack != nil ? Theme.purple : Color.gray).opacity(0.4),
                Theme.navy
            ],
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
    }

    private var historyStrip: some View {
        HStack(spacing: 20) {
            ForEach(recentTracks.prefix(3)) { track in
                HStack(spacing: 10) {
                    AlbumArtView(artworkData: track.artworkData, size: 48)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(1)
                        Text(track.artist)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.midnightBlue.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
