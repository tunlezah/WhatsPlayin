import XCTest
@testable import WhatsPlayin

final class StubProviderTests: XCTestCase {

    func test_name_isStubFallback() {
        let provider = StubProvider()
        XCTAssertEqual(provider.name, "StubFallback")
    }

    func test_identify_returnsNil() async {
        let provider = StubProvider()
        let result = await provider.identify(audioData: Data([1, 2, 3]))
        XCTAssertNil(result, "StubProvider should always return nil")
    }

    func test_identify_emptyData_returnsNil() async {
        let provider = StubProvider()
        let result = await provider.identify(audioData: Data())
        XCTAssertNil(result, "StubProvider should return nil even with empty data")
    }

    func test_conformsToMusicRecognitionProvider() {
        let provider: MusicRecognitionProvider = StubProvider()
        XCTAssertNotNil(provider)
        XCTAssertEqual(provider.name, "StubFallback")
    }
}
