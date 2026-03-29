import Foundation

final class AcoustIDProvider: MusicRecognitionProvider {
    let name = "AcoustID"
    private let settings: AppSettings
    private let fingerprintService: FingerprintService
    private let logger = AppLogger.shared

    init(settings: AppSettings = .shared, fingerprintService: FingerprintService = FingerprintService()) {
        self.settings = settings
        self.fingerprintService = fingerprintService
    }

    func identify(audioData: Data) async -> IdentificationResult? {
        guard !settings.acoustIDApiKey.isEmpty else {
            logger.error("AcoustID API key not configured", category: .recognition)
            return nil
        }

        guard let fingerprint = fingerprintService.generateFingerprint(from: audioData) else {
            logger.error("Failed to generate fingerprint", category: .fingerprint)
            return nil
        }

        logger.info("Submitting fingerprint to AcoustID (duration: \(fingerprint.duration)s)", category: .recognition)

        do {
            let response = try await submitToAcoustID(fingerprint: fingerprint.fingerprint, duration: fingerprint.duration)
            return parseResponse(response, fingerprintHash: fingerprint.hash)
        } catch {
            logger.error("AcoustID API error: \(error.localizedDescription)", category: .network)
            return nil
        }
    }

    // MARK: - Private

    private func submitToAcoustID(fingerprint: String, duration: Int) async throws -> AcoustIDResponse {
        var components = URLComponents(string: Constants.API.acoustIDBaseURL)!
        components.queryItems = [
            URLQueryItem(name: "client", value: settings.acoustIDApiKey),
            URLQueryItem(name: "fingerprint", value: fingerprint),
            URLQueryItem(name: "duration", value: String(duration)),
            URLQueryItem(name: "meta", value: "recordings+releasegroups")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15

        logger.debug("AcoustID request URL: \(url.absoluteString.prefix(100))...", category: .network)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        logger.debug("AcoustID response status: \(httpResponse.statusCode)", category: .network)
        logger.debug("AcoustID response body: \(String(data: data, encoding: .utf8) ?? "nil")", category: .network)

        guard httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(AcoustIDResponse.self, from: data)
    }

    private func parseResponse(_ response: AcoustIDResponse, fingerprintHash: String) -> IdentificationResult? {
        guard response.status == "ok",
              let results = response.results,
              let bestResult = results.first,
              bestResult.score > 0 else {
            logger.info("No results from AcoustID", category: .recognition)
            return nil
        }

        guard let recording = bestResult.recordings?.first else {
            logger.info("AcoustID result has no recordings", category: .recognition)
            return nil
        }

        let artistName = recording.artists?.map(\.name).joined(separator: ", ")
        let releaseGroup = recording.releasegroups?.first

        logger.info("AcoustID match: \(recording.title ?? "?") by \(artistName ?? "?") (score: \(bestResult.score))", category: .recognition)

        return IdentificationResult(
            title: recording.title,
            artist: artistName,
            album: releaseGroup?.title,
            releaseYear: nil, // Will be resolved via MusicBrainz
            musicBrainzRecordingID: recording.id,
            musicBrainzReleaseID: releaseGroup?.id,
            confidence: bestResult.score,
            fingerprintHash: fingerprintHash,
            provider: name
        )
    }
}
