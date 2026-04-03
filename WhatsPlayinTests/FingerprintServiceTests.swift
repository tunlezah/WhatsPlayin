import XCTest
@testable import WhatsPlayin

final class FingerprintServiceTests: XCTestCase {
    private var service: FingerprintService!

    override func setUp() {
        super.setUp()
        service = FingerprintService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - Empty / Invalid Input

    func test_generateFingerprint_emptyData_returnsNil() {
        let result = service.generateFingerprint(from: Data())
        XCTAssertNil(result, "Empty data should return nil")
    }

    func test_generateFingerprint_tooShort_returnsNil() {
        // At 11025 Hz, 5 seconds = 55125 samples = 110250 bytes (16-bit)
        // Create data shorter than 5 seconds
        let shortData = Data(repeating: 0, count: 44100) // ~2 seconds
        let result = service.generateFingerprint(from: shortData)
        XCTAssertNil(result, "Audio shorter than 5 seconds should return nil")
    }

    // MARK: - Valid Input

    func test_generateFingerprint_validAudio_returnsResult() {
        // Generate 10 seconds of silence at 11025 Hz (16-bit mono)
        let sampleCount = 11025 * 10
        var data = Data(capacity: sampleCount * 2)
        for _ in 0..<sampleCount {
            var sample: Int16 = 0
            data.append(Data(bytes: &sample, count: 2))
        }

        let result = service.generateFingerprint(from: data)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.duration, 10)
        XCTAssertFalse(result?.fingerprint.isEmpty ?? true)
        XCTAssertFalse(result?.hash.isEmpty ?? true)
    }

    func test_generateFingerprint_withTone_returnsNonEmptyFingerprint() {
        // Generate 6 seconds of a simple sine wave pattern
        let sampleRate = 11025
        let duration = 6
        let sampleCount = sampleRate * duration
        var data = Data(capacity: sampleCount * 2)

        for i in 0..<sampleCount {
            // 440 Hz tone
            let phase = Double(i) * 440.0 / Double(sampleRate) * 2.0 * .pi
            let value = Int16(sin(phase) * Double(Int16.max / 2))
            var sample = value
            data.append(Data(bytes: &sample, count: 2))
        }

        let result = service.generateFingerprint(from: data)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.duration, 6)
        XCTAssertFalse(result?.fingerprint.isEmpty ?? true)
    }

    func test_generateFingerprint_differentAudio_differentHashes() {
        let sampleCount = 11025 * 6 // 6 seconds

        // Audio 1: silence
        var data1 = Data(repeating: 0, count: sampleCount * 2)

        // Audio 2: noise pattern
        var data2 = Data(capacity: sampleCount * 2)
        for i in 0..<sampleCount {
            var sample = Int16(i % 32767)
            data2.append(Data(bytes: &sample, count: 2))
        }

        let result1 = service.generateFingerprint(from: data1)
        let result2 = service.generateFingerprint(from: data2)

        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        XCTAssertNotEqual(result1?.hash, result2?.hash, "Different audio should produce different hashes")
    }

    // MARK: - Duration Calculation

    func test_generateFingerprint_correctDuration() {
        let sampleRate = 11025
        let durations = [5, 10, 20]

        for expectedDuration in durations {
            let sampleCount = sampleRate * expectedDuration
            var data = Data(capacity: sampleCount * 2)
            for _ in 0..<sampleCount {
                var sample: Int16 = 100
                data.append(Data(bytes: &sample, count: 2))
            }

            let result = service.generateFingerprint(from: data, sampleRate: sampleRate)
            XCTAssertEqual(result?.duration, expectedDuration, "Duration should be \(expectedDuration)s")
        }
    }

    // MARK: - Custom Sample Rate

    func test_generateFingerprint_customSampleRate() {
        let sampleRate = 44100
        let sampleCount = sampleRate * 6 // 6 seconds
        var data = Data(capacity: sampleCount * 2)
        for i in 0..<sampleCount {
            var sample = Int16(i % 1000)
            data.append(Data(bytes: &sample, count: 2))
        }

        let result = service.generateFingerprint(from: data, sampleRate: sampleRate)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.duration, 6)
    }
}
