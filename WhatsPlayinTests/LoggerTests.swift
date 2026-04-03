import XCTest
@testable import WhatsPlayin

final class LoggerTests: XCTestCase {

    // MARK: - DebugLogEntry

    func test_debugLogEntry_levelString() {
        let entry = DebugLogEntry(
            timestamp: Date(),
            category: .audio,
            level: .info,
            message: "test"
        )
        XCTAssertEqual(entry.levelString, "INFO")
        XCTAssertNotNil(entry.id)
        XCTAssertEqual(entry.category, .audio)
        XCTAssertEqual(entry.message, "test")
    }

    func test_debugLogEntry_allLevelStrings() {
        let levels: [(level: OSLogType, expected: String)] = [
            (.debug, "DEBUG"),
            (.info, "INFO"),
            (.error, "ERROR"),
            (.fault, "FAULT"),
        ]

        for (level, expected) in levels {
            let entry = DebugLogEntry(
                timestamp: Date(),
                category: .general,
                level: level,
                message: "test"
            )
            XCTAssertEqual(entry.levelString, expected, "Level \(level) should map to '\(expected)'")
        }
    }

    // MARK: - LogCategory

    func test_logCategory_rawValues() {
        XCTAssertEqual(LogCategory.audio.rawValue, "Audio")
        XCTAssertEqual(LogCategory.fingerprint.rawValue, "Fingerprint")
        XCTAssertEqual(LogCategory.recognition.rawValue, "Recognition")
        XCTAssertEqual(LogCategory.metadata.rawValue, "Metadata")
        XCTAssertEqual(LogCategory.coverArt.rawValue, "CoverArt")
        XCTAssertEqual(LogCategory.ui.rawValue, "UI")
        XCTAssertEqual(LogCategory.network.rawValue, "Network")
        XCTAssertEqual(LogCategory.general.rawValue, "General")
    }

    // MARK: - AppLogger

    func test_appLogger_shared_isSingleton() {
        let a = AppLogger.shared
        let b = AppLogger.shared
        XCTAssertTrue(a === b)
    }

    func test_appLogger_clearDebugEntries() {
        let logger = AppLogger.shared

        // Log something
        logger.info("test entry", category: .general)

        // Wait for main queue dispatch
        let expectation = expectation(description: "clear entries")
        DispatchQueue.main.async {
            logger.clearDebugEntries()
            DispatchQueue.main.async {
                XCTAssertTrue(logger.debugEntries.isEmpty)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 2.0)
    }
}
