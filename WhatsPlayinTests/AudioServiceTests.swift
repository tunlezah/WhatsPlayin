import XCTest
@testable import WhatsPlayin

final class AudioServiceTests: XCTestCase {
    private var service: AudioService!

    override func setUp() {
        super.setUp()
        service = AudioService()
    }

    override func tearDown() {
        service.stopListening()
        service = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func test_initialState_isIdle() {
        XCTAssertTrue(isIdle(service.state))
    }

    func test_initialLevel_isZero() {
        XCTAssertEqual(service.currentLevel, 0)
    }

    func test_initialBufferFillPercent_isZero() {
        XCTAssertEqual(service.bufferFillPercent, 0)
    }

    // MARK: - Buffer Data

    func test_getBufferData_whenEmpty_returnsNil() {
        XCTAssertNil(service.getBufferData())
    }

    func test_bufferDurationSeconds_whenEmpty_isZero() {
        XCTAssertEqual(service.bufferDurationSeconds, 0)
    }

    // MARK: - Silence Detection

    func test_isSilent_whenLevelBelowThreshold_returnsTrue() {
        // Initial level is 0, which is below threshold
        XCTAssertTrue(service.isSilent)
    }

    // MARK: - Stop Listening

    func test_stopListening_resetsState() {
        // stopListening should be safe to call even when idle
        service.stopListening()

        XCTAssertTrue(isIdle(service.state))
        XCTAssertEqual(service.currentLevel, 0)
        XCTAssertEqual(service.bufferFillPercent, 0)
        XCTAssertNil(service.getBufferData())
    }

    func test_stopListening_calledMultipleTimes_doesNotCrash() {
        service.stopListening()
        service.stopListening()
        service.stopListening()
        // Should not crash
        XCTAssertTrue(isIdle(service.state))
    }

    // MARK: - State Enum

    func test_audioServiceState_cases() {
        // Verify all states are constructible
        let idle: AudioServiceState = .idle
        let requesting: AudioServiceState = .requestingPermission
        let listening: AudioServiceState = .listening
        let error: AudioServiceState = .error("test error")

        XCTAssertTrue(isIdle(idle))
        XCTAssertTrue(isRequestingPermission(requesting))
        XCTAssertTrue(isListening(listening))
        XCTAssertTrue(isError(error))
    }

    // MARK: - Helpers

    private func isIdle(_ state: AudioServiceState) -> Bool {
        if case .idle = state { return true }
        return false
    }

    private func isRequestingPermission(_ state: AudioServiceState) -> Bool {
        if case .requestingPermission = state { return true }
        return false
    }

    private func isListening(_ state: AudioServiceState) -> Bool {
        if case .listening = state { return true }
        return false
    }

    private func isError(_ state: AudioServiceState) -> Bool {
        if case .error = state { return true }
        return false
    }
}
