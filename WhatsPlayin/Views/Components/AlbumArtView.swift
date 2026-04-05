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
                        colors: [Theme.purple.opacity(0.3), Theme.cyan.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.3))
                        .foregroundStyle(Theme.cyan.opacity(0.6))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.06))
        .shadow(color: Theme.cyan.opacity(0.15), radius: 10, y: 5)
    }
}
