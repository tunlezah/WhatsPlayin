import Foundation

protocol MusicRecognitionProvider {
    var name: String { get }
    func identify(audioData: Data) async -> IdentificationResult?
}
