import XCTest
@testable import WhatsPlayin

final class TrackTests: XCTestCase {

    // MARK: - Initialization

    func test_init_setsAllProperties() {
        let date = Date()
        let url = URL(string: "https://example.com/art.jpg")!
        let data = Data([0xFF, 0xD8])
        let track = Track(
            title: "Song",
            artist: "Artist",
            album: "Album",
            releaseYear: 2024,
            musicBrainzID: "mb-id",
            confidence: 0.95,
            detectedAt: date,
            artworkURL: url,
            artworkData: data
        )

        XCTAssertEqual(track.title, "Song")
        XCTAssertEqual(track.artist, "Artist")
        XCTAssertEqual(track.album, "Album")
        XCTAssertEqual(track.releaseYear, 2024)
        XCTAssertEqual(track.musicBrainzID, "mb-id")
        XCTAssertEqual(track.confidence, 0.95)
        XCTAssertEqual(track.detectedAt, date)
        XCTAssertEqual(track.artworkURL, url)
        XCTAssertEqual(track.artworkData, data)
    }

    func test_init_defaultValues() {
        let track = Track(title: "Song", artist: "Artist", confidence: 0.5)

        XCTAssertNil(track.album)
        XCTAssertNil(track.releaseYear)
        XCTAssertNil(track.musicBrainzID)
        XCTAssertNil(track.artworkURL)
        XCTAssertNil(track.artworkData)
        XCTAssertNotNil(track.id)
        XCTAssertNotNil(track.detectedAt)
    }

    // MARK: - Computed Properties

    func test_displayTitle_formatsCorrectly() {
        let track = Track(title: "Bohemian Rhapsody", artist: "Queen", confidence: 0.99)
        XCTAssertEqual(track.displayTitle, "Bohemian Rhapsody — Queen")
    }

    func test_confidencePercent_convertsCorrectly() {
        let track95 = Track(title: "A", artist: "B", confidence: 0.95)
        XCTAssertEqual(track95.confidencePercent, 95)

        let track0 = Track(title: "A", artist: "B", confidence: 0.0)
        XCTAssertEqual(track0.confidencePercent, 0)

        let track100 = Track(title: "A", artist: "B", confidence: 1.0)
        XCTAssertEqual(track100.confidencePercent, 100)

        let track33 = Track(title: "A", artist: "B", confidence: 0.337)
        XCTAssertEqual(track33.confidencePercent, 33)
    }

    // MARK: - Equatable

    func test_equality_basedOnID() {
        let id = UUID()
        let track1 = Track(id: id, title: "Song A", artist: "Artist A", confidence: 0.9)
        let track2 = Track(id: id, title: "Song B", artist: "Artist B", confidence: 0.5)

        XCTAssertEqual(track1, track2, "Tracks with same ID should be equal regardless of other properties")
    }

    func test_inequality_differentIDs() {
        let track1 = Track(title: "Song", artist: "Artist", confidence: 0.9)
        let track2 = Track(title: "Song", artist: "Artist", confidence: 0.9)

        XCTAssertNotEqual(track1, track2, "Tracks with different IDs should not be equal")
    }

    // MARK: - Codable

    func test_codable_roundTrip() throws {
        let original = Track(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            releaseYear: 2023,
            musicBrainzID: "abc-123",
            confidence: 0.88,
            artworkURL: URL(string: "https://example.com/art.jpg")
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Track.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.artist, original.artist)
        XCTAssertEqual(decoded.album, original.album)
        XCTAssertEqual(decoded.releaseYear, original.releaseYear)
        XCTAssertEqual(decoded.musicBrainzID, original.musicBrainzID)
        XCTAssertEqual(decoded.confidence, original.confidence, accuracy: 0.001)
    }

    func test_codable_withNilOptionals() throws {
        let original = Track(title: "Minimal", artist: "Track", confidence: 0.5)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Track.self, from: data)

        XCTAssertEqual(decoded.title, "Minimal")
        XCTAssertEqual(decoded.artist, "Track")
        XCTAssertNil(decoded.album)
        XCTAssertNil(decoded.releaseYear)
        XCTAssertNil(decoded.musicBrainzID)
        XCTAssertNil(decoded.artworkURL)
        XCTAssertNil(decoded.artworkData)
    }
}
