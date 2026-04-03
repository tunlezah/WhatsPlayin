import XCTest
@testable import WhatsPlayin

final class IdentificationResultTests: XCTestCase {

    // MARK: - isValid

    func test_isValid_withTitleArtistAndConfidence() {
        let result = IdentificationResult(
            title: "Song",
            artist: "Artist",
            album: nil,
            releaseYear: nil,
            musicBrainzRecordingID: nil,
            musicBrainzReleaseID: nil,
            confidence: 0.9,
            fingerprintHash: "abc",
            provider: "test"
        )
        XCTAssertTrue(result.isValid)
    }

    func test_isValid_nilTitle_returnsFalse() {
        let result = IdentificationResult(
            title: nil,
            artist: "Artist",
            album: nil,
            releaseYear: nil,
            musicBrainzRecordingID: nil,
            musicBrainzReleaseID: nil,
            confidence: 0.9,
            fingerprintHash: "abc",
            provider: "test"
        )
        XCTAssertFalse(result.isValid)
    }

    func test_isValid_nilArtist_returnsFalse() {
        let result = IdentificationResult(
            title: "Song",
            artist: nil,
            album: nil,
            releaseYear: nil,
            musicBrainzRecordingID: nil,
            musicBrainzReleaseID: nil,
            confidence: 0.9,
            fingerprintHash: "abc",
            provider: "test"
        )
        XCTAssertFalse(result.isValid)
    }

    func test_isValid_zeroConfidence_returnsFalse() {
        let result = IdentificationResult(
            title: "Song",
            artist: "Artist",
            album: nil,
            releaseYear: nil,
            musicBrainzRecordingID: nil,
            musicBrainzReleaseID: nil,
            confidence: 0.0,
            fingerprintHash: "abc",
            provider: "test"
        )
        XCTAssertFalse(result.isValid)
    }

    func test_isValid_negativeConfidence_returnsFalse() {
        let result = IdentificationResult(
            title: "Song",
            artist: "Artist",
            album: nil,
            releaseYear: nil,
            musicBrainzRecordingID: nil,
            musicBrainzReleaseID: nil,
            confidence: -0.1,
            fingerprintHash: "abc",
            provider: "test"
        )
        XCTAssertFalse(result.isValid)
    }
}

// MARK: - AcoustIDResponse Decoding

final class AcoustIDResponseTests: XCTestCase {

    func test_decode_validResponse() throws {
        let json = """
        {
            "status": "ok",
            "results": [
                {
                    "id": "result-1",
                    "score": 0.95,
                    "recordings": [
                        {
                            "id": "rec-1",
                            "title": "Test Song",
                            "artists": [{"id": "art-1", "name": "Test Artist"}],
                            "releasegroups": [
                                {
                                    "id": "rg-1",
                                    "title": "Test Album",
                                    "type": "Album"
                                }
                            ]
                        }
                    ]
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(AcoustIDResponse.self, from: data)

        XCTAssertEqual(response.status, "ok")
        XCTAssertEqual(response.results?.count, 1)
        XCTAssertEqual(response.results?.first?.score, 0.95)
        XCTAssertEqual(response.results?.first?.recordings?.first?.title, "Test Song")
        XCTAssertEqual(response.results?.first?.recordings?.first?.artists?.first?.name, "Test Artist")
        XCTAssertEqual(response.results?.first?.recordings?.first?.releasegroups?.first?.title, "Test Album")
    }

    func test_decode_emptyResults() throws {
        let json = """
        {"status": "ok", "results": []}
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(AcoustIDResponse.self, from: data)

        XCTAssertEqual(response.status, "ok")
        XCTAssertEqual(response.results?.count, 0)
    }

    func test_decode_errorStatus() throws {
        let json = """
        {"status": "error", "results": null}
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(AcoustIDResponse.self, from: data)

        XCTAssertEqual(response.status, "error")
        XCTAssertNil(response.results)
    }
}

// MARK: - MusicBrainzRecordingResponse Decoding

final class MusicBrainzRecordingResponseTests: XCTestCase {

    func test_decode_withReleases() throws {
        let json = """
        {
            "id": "rec-123",
            "title": "Song Title",
            "releases": [
                {
                    "id": "rel-1",
                    "title": "Album Title",
                    "date": "2023-05-15"
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(MusicBrainzRecordingResponse.self, from: data)

        XCTAssertEqual(response.id, "rec-123")
        XCTAssertEqual(response.title, "Song Title")
        XCTAssertEqual(response.releases?.count, 1)
        XCTAssertEqual(response.releases?.first?.title, "Album Title")
        XCTAssertEqual(response.releases?.first?.date, "2023-05-15")
    }

    func test_decode_noReleases() throws {
        let json = """
        {"id": "rec-456", "title": "Solo Track"}
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(MusicBrainzRecordingResponse.self, from: data)

        XCTAssertEqual(response.id, "rec-456")
        XCTAssertNil(response.releases)
    }
}

// MARK: - CoverArtResponse Decoding

final class CoverArtResponseTests: XCTestCase {

    func test_decode_withThumbnails() throws {
        let json = """
        {
            "images": [
                {
                    "image": "https://example.com/full.jpg",
                    "thumbnails": {
                        "small": "https://example.com/small.jpg",
                        "large": "https://example.com/large.jpg",
                        "250": "https://example.com/250.jpg",
                        "500": "https://example.com/500.jpg",
                        "1200": "https://example.com/1200.jpg"
                    },
                    "front": true
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(CoverArtResponse.self, from: data)

        XCTAssertEqual(response.images.count, 1)
        XCTAssertTrue(response.images[0].front == true)
        XCTAssertEqual(response.images[0].thumbnails?.the500, "https://example.com/500.jpg")
        XCTAssertEqual(response.images[0].thumbnails?.the250, "https://example.com/250.jpg")
        XCTAssertEqual(response.images[0].thumbnails?.the1200, "https://example.com/1200.jpg")
    }

    func test_decode_noThumbnails() throws {
        let json = """
        {
            "images": [
                {
                    "image": "https://example.com/full.jpg"
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(CoverArtResponse.self, from: data)

        XCTAssertEqual(response.images.count, 1)
        XCTAssertNil(response.images[0].front)
        XCTAssertNil(response.images[0].thumbnails)
    }

    func test_decode_emptyImages() throws {
        let json = """
        {"images": []}
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(CoverArtResponse.self, from: data)

        XCTAssertTrue(response.images.isEmpty)
    }
}
