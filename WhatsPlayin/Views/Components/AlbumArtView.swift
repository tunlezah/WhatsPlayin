import SwiftUI

struct AlbumArtView: View {
    let artworkData: Data?
    let size: CGFloat

    init(artworkData: Data? = nil, size: CGFloat = 200) {
        self.artworkData = artworkData
        self.size = size
    }

    var body: some View {
        Group {
            if let data = artworkData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    LinearGradient(
                        colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.3))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.06))
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }
}
