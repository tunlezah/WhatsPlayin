import Foundation

/// Stub fallback provider placeholder for future Shazam-like integration.
/// Returns nil — serves as an extension point for additional recognition services.
final class StubProvider: MusicRecognitionProvider {
    let name = "StubFallback"
    private let logger = AppLogger.shared

    func identify(audioData: Data) async -> IdentificationResult? {
        logger.info("Stub provider called — no implementation available", category: .recognition)
        // Placeholder for future integration (e.g., ShazamKit)
        // To implement: use ShazamKit's SHManagedSession for recognition
        return nil
    }
}
