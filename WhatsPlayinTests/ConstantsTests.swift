import XCTest
@testable import WhatsPlayin

final class ConstantsTests: XCTestCase {

    // MARK: - Audio Constants

    func test_audioConstants_validRanges() {
        XCTAssertGreaterThan(Constants.Audio.defaultSampleRate, 0)
        XCTAssertGreaterThan(Constants.Audio.highSampleRate, Constants.Audio.defaultSampleRate)
        XCTAssertEqual(Constants.Audio.channelCount, 1, "Should be mono")
        XCTAssertEqual(Constants.Audio.bitDepth, 16)
        XCTAssertGreaterThan(Constants.Audio.noiseGateThreshold, 0)
        XCTAssertLessThan(Constants.Audio.noiseGateThreshold, 1)
    }

    func test_audioBufferDuration_validRange() {
        XCTAssertGreaterThan(Constants.Audio.minBufferDuration, 0)
        XCTAssertLessThan(Constants.Audio.minBufferDuration, Constants.Audio.maxBufferDuration)
        XCTAssertGreaterThanOrEqual(Constants.Audio.defaultBufferDuration, Constants.Audio.minBufferDuration)
        XCTAssertLessThanOrEqual(Constants.Audio.defaultBufferDuration, Constants.Audio.maxBufferDuration)
    }

    // MARK: - Detection Constants

    func test_detectionConstants_validRanges() {
        XCTAssertGreaterThan(Constants.Detection.defaultInterval, 0)
        XCTAssertGreaterThanOrEqual(Constants.Detection.defaultInterval, Constants.Detection.minInterval)
        XCTAssertLessThanOrEqual(Constants.Detection.defaultInterval, Constants.Detection.maxInterval)
        XCTAssertGreaterThan(Constants.Detection.defaultConfidenceThreshold, 0)
        XCTAssertLessThanOrEqual(Constants.Detection.defaultConfidenceThreshold, 1.0)
        XCTAssertGreaterThan(Constants.Detection.defaultCooldownDuration, 0)
        XCTAssertGreaterThan(Constants.Detection.defaultPerTrackCooldown, 0)
        XCTAssertGreaterThan(Constants.Detection.silenceThreshold, 0)
    }

    // MARK: - History Constants

    func test_historyConstants() {
        XCTAssertGreaterThan(Constants.History.maxTracks, 0)
    }

    // MARK: - API Constants

    func test_apiConstants_validURLs() {
        XCTAssertFalse(Constants.API.acoustIDBaseURL.isEmpty)
        XCTAssertFalse(Constants.API.musicBrainzBaseURL.isEmpty)
        XCTAssertFalse(Constants.API.coverArtBaseURL.isEmpty)

        XCTAssertNotNil(URL(string: Constants.API.acoustIDBaseURL), "AcoustID URL should be valid")
        XCTAssertNotNil(URL(string: Constants.API.musicBrainzBaseURL), "MusicBrainz URL should be valid")
        XCTAssertNotNil(URL(string: Constants.API.coverArtBaseURL), "Cover Art URL should be valid")
    }

    func test_apiConstants_userAgent() {
        XCTAssertFalse(Constants.API.musicBrainzUserAgent.isEmpty)
        XCTAssertTrue(Constants.API.musicBrainzUserAgent.contains("WhatsPlayin"))
    }

    func test_apiConstants_rateLimit() {
        XCTAssertGreaterThan(Constants.API.musicBrainzRateLimit, 0)
    }
}
