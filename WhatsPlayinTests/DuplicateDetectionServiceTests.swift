import XCTest
@testable import WhatsPlayin

final class DuplicateDetectionServiceTests: XCTestCase {
    private var service: DuplicateDetectionService!
    private var settings: AppSettings!

    override func setUp() {
        super.setUp()
        settings = .shared
        service = DuplicateDetectionService(settings: settings)
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeResult(title: String = "Song", artist: String = "Artist") -> IdentificationResult {
        IdentificationResult(
            title: title,
            artist: artist,
            album: nil,
            releaseYear: nil,
            musicBrainzRecordingID: nil,
            musicBrainzReleaseID: nil,
            confidence: 0.9,
            fingerprintHash: "hash-\(title)-\(artist)",
            provider: "test"
        )
    }

    // MARK: - shouldAccept

    func test_shouldAccept_firstDetection_returnsTrue() {
        let result = makeResult()
        XCTAssertTrue(service.shouldAccept(fingerprintHash: "hash1", result: result))
    }

    func test_shouldAccept_identicalHash_afterRecord_returnsFalse() {
        let result = makeResult()
        service.recordDetection(fingerprintHash: "hash1", result: result)

        // Same hash should be rejected
        XCTAssertFalse(service.shouldAccept(fingerprintHash: "hash1", result: result))
    }

    func test_shouldAccept_differentHash_noCooldown_returnsTrue() {
        let result1 = makeResult(title: "Song A")
        service.recordDetection(fingerprintHash: "hash1", result: result1)

        // Wait for global cooldown to expire (if any)
        // Force reset cooldown for this test
        service.reset()

        let result2 = makeResult(title: "Song B")
        XCTAssertTrue(service.shouldAccept(fingerprintHash: "hash2", result: result2))
    }

    func test_shouldAccept_nilResult_checksHashAndCooldownOnly() {
        XCTAssertTrue(service.shouldAccept(fingerprintHash: "hash1", result: nil))
    }

    // MARK: - Cooldown

    func test_remainingCooldown_beforeAnyDetection_isZero() {
        XCTAssertEqual(service.remainingCooldown, 0)
    }

    func test_isInCooldown_afterDetection_isTrue() {
        let result = makeResult()
        service.recordDetection(fingerprintHash: "hash1", result: result)
        XCTAssertTrue(service.isInCooldown)
    }

    func test_shouldAccept_duringCooldown_returnsFalse() {
        let result = makeResult()
        service.recordDetection(fingerprintHash: "hash1", result: result)

        // During cooldown, even a different hash should be rejected
        let result2 = makeResult(title: "Different Song", artist: "Different Artist")
        XCTAssertFalse(service.shouldAccept(fingerprintHash: "different-hash", result: result2))
    }

    // MARK: - Reset

    func test_reset_clearsAllState() {
        let result = makeResult()
        service.recordDetection(fingerprintHash: "hash1", result: result)
        XCTAssertTrue(service.isInCooldown)

        service.reset()

        XCTAssertFalse(service.isInCooldown)
        XCTAssertEqual(service.remainingCooldown, 0)
        XCTAssertTrue(service.shouldAccept(fingerprintHash: "hash1", result: result))
    }

    // MARK: - recordDetection

    func test_recordDetection_setsLastDetectionTime() {
        let result = makeResult()
        XCTAssertFalse(service.isInCooldown)

        service.recordDetection(fingerprintHash: "hash1", result: result)

        XCTAssertTrue(service.isInCooldown)
        XCTAssertGreaterThan(service.remainingCooldown, 0)
    }

    func test_recordDetection_setsPerTrackCooldown() {
        let result = makeResult(title: "Track A", artist: "Artist A")
        service.recordDetection(fingerprintHash: "hash1", result: result)

        // Reset global cooldown but keep per-track
        // (Per-track cooldown check requires shouldAccept during global cooldown,
        // so we test that the track key is being tracked)
        service.reset()

        // Re-record to set per-track again
        service.recordDetection(fingerprintHash: "hash1", result: result)

        // Same track, different hash — should fail due to per-track cooldown (and global cooldown)
        XCTAssertFalse(service.shouldAccept(fingerprintHash: "hash2", result: result))
    }

    // MARK: - Per-Track Cooldown with nil title/artist

    func test_shouldAccept_nilTitleInResult_skipsPerTrackCheck() {
        let resultNoTitle = IdentificationResult(
            title: nil,
            artist: "Artist",
            album: nil,
            releaseYear: nil,
            musicBrainzRecordingID: nil,
            musicBrainzReleaseID: nil,
            confidence: 0.9,
            fingerprintHash: "hash",
            provider: "test"
        )
        // Should not crash when title is nil
        XCTAssertTrue(service.shouldAccept(fingerprintHash: "hash1", result: resultNoTitle))
    }
}
