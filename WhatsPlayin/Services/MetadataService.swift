import Foundation

/// Resolves additional metadata from MusicBrainz
final class MetadataService {
    private let logger = AppLogger.shared
    private var lastRequestTime: Date?

    /// Fetch additional metadata for a recording from MusicBrainz
    func enrichResult(_ result: IdentificationResult) async -> IdentificationResult {
        guard let recordingID = result.musicBrainzRecordingID else {
            return result
        }

        await respectRateLimit()

        do {
            let recording = try await fetchRecording(id: recordingID)
            let release = recording.releases?.first
            let year = parseYear(from: release?.date)

            logger.info("MusicBrainz enrichment: album=\(release?.title ?? "?"), year=\(year.map(String.init) ?? "?")", category: .metadata)

            return IdentificationResult(
                title: result.title ?? recording.title,
                artist: result.artist,
                album: result.album ?? release?.title,
                releaseYear: year ?? result.releaseYear,
                musicBrainzRecordingID: result.musicBrainzRecordingID,
                musicBrainzReleaseID: release?.id ?? result.musicBrainzReleaseID,
                confidence: result.confidence,
                fingerprintHash: result.fingerprintHash,
                provider: result.provider
            )
        } catch {
            logger.error("MusicBrainz fetch error: \(error.localizedDescription)", category: .metadata)
            return result
        }
    }

    // MARK: - Private

    private func fetchRecording(id: String) async throws -> MusicBrainzRecordingResponse {
        let urlString = "\(Constants.API.musicBrainzBaseURL)/recording/\(id)?inc=releases&fmt=json"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue(Constants.API.musicBrainzUserAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        lastRequestTime = Date()
        return try JSONDecoder().decode(MusicBrainzRecordingResponse.self, from: data)
    }

    private func respectRateLimit() async {
        if let last = lastRequestTime {
            let elapsed = Date().timeIntervalSince(last)
            let waitTime = Constants.API.musicBrainzRateLimit - elapsed
            if waitTime > 0 {
                try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
        }
    }

    private func parseYear(from dateString: String?) -> Int? {
        guard let dateString = dateString else { return nil }
        let components = dateString.split(separator: "-")
        guard let yearStr = components.first else { return nil }
        return Int(yearStr)
    }
}
