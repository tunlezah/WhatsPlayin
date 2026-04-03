import XCTest
@testable import WhatsPlayin

final class AppStateTests: XCTestCase {

    // MARK: - statusText

    func test_statusText_allCases() {
        XCTAssertEqual(AppState.idle.statusText, "Ready")
        XCTAssertEqual(AppState.listening.statusText, "Listening…")
        XCTAssertEqual(AppState.processing.statusText, "Processing…")
        XCTAssertEqual(AppState.coolingDown.statusText, "Cooling down")

        let track = Track(title: "Song", artist: "Artist", confidence: 0.9)
        XCTAssertEqual(AppState.identified(track).statusText, "Identified")

        XCTAssertEqual(AppState.error("Bad stuff").statusText, "Error: Bad stuff")
    }

    // MARK: - Equatable

    func test_equality_sameSimpleCases() {
        XCTAssertEqual(AppState.idle, AppState.idle)
        XCTAssertEqual(AppState.listening, AppState.listening)
        XCTAssertEqual(AppState.processing, AppState.processing)
        XCTAssertEqual(AppState.coolingDown, AppState.coolingDown)
    }

    func test_equality_errorCases() {
        XCTAssertEqual(AppState.error("msg"), AppState.error("msg"))
        XCTAssertNotEqual(AppState.error("a"), AppState.error("b"))
    }

    func test_equality_identifiedCases() {
        let id = UUID()
        let track1 = Track(id: id, title: "A", artist: "B", confidence: 0.9)
        let track2 = Track(id: id, title: "A", artist: "B", confidence: 0.9)
        XCTAssertEqual(AppState.identified(track1), AppState.identified(track2))
    }

    func test_inequality_differentCases() {
        XCTAssertNotEqual(AppState.idle, AppState.listening)
        XCTAssertNotEqual(AppState.processing, AppState.coolingDown)
        XCTAssertNotEqual(AppState.idle, AppState.error("x"))

        let track = Track(title: "A", artist: "B", confidence: 0.5)
        XCTAssertNotEqual(AppState.idle, AppState.identified(track))
    }

    func test_inequality_identifiedDifferentTracks() {
        let track1 = Track(title: "A", artist: "B", confidence: 0.5)
        let track2 = Track(title: "C", artist: "D", confidence: 0.5)
        XCTAssertNotEqual(AppState.identified(track1), AppState.identified(track2))
    }
}
