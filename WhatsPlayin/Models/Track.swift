import Foundation
import SwiftUI

struct Track: Identifiable, Equatable, Codable {
    let id: UUID
    let title: String
    let artist: String
    let album: String?
    let releaseYear: Int?
    let musicBrainzID: String?
    let confidence: Double
    let detectedAt: Date
    var artworkURL: URL?
    var artworkData: Data?

    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        album: String? = nil,
        releaseYear: Int? = nil,
        musicBrainzID: String? = nil,
        confidence: Double,
        detectedAt: Date = Date(),
        artworkURL: URL? = nil,
        artworkData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.releaseYear = releaseYear
        self.musicBrainzID = musicBrainzID
        self.confidence = confidence
        self.detectedAt = detectedAt
        self.artworkURL = artworkURL
        self.artworkData = artworkData
    }

    var displayTitle: String {
        "\(title) — \(artist)"
    }

    var confidencePercent: Int {
        Int(confidence * 100)
    }

    static func == (lhs: Track, rhs: Track) -> Bool {
        lhs.id == rhs.id
    }
}
