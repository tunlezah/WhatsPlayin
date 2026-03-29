import Foundation

/// Fetches album artwork from the Cover Art Archive
final class CoverArtService {
    private let logger = AppLogger.shared
    private let cache = NSCache<NSString, NSData>()

    init() {
        cache.countLimit = 50
    }

    /// Fetch cover art for a MusicBrainz release
    func fetchArtwork(releaseID: String) async -> (url: URL?, data: Data?) {
        // Check cache
        if let cached = cache.object(forKey: releaseID as NSString) {
            return (nil, cached as Data)
        }

        do {
            let artInfo = try await fetchCoverArtInfo(releaseID: releaseID)
            guard let frontImage = artInfo.images.first(where: { $0.front == true }) ?? artInfo.images.first else {
                logger.info("No cover art found for release \(releaseID)", category: .coverArt)
                return (nil, nil)
            }

            // Prefer 500px thumbnail, fall back to large, then full
            let imageURLString = frontImage.thumbnails?.the500
                ?? frontImage.thumbnails?.large
                ?? frontImage.image
            guard let imageURL = URL(string: imageURLString) else {
                return (nil, nil)
            }

            let imageData = try await downloadImage(url: imageURL)
            cache.setObject(imageData as NSData, forKey: releaseID as NSString)

            logger.info("Cover art fetched for release \(releaseID) (\(imageData.count) bytes)", category: .coverArt)
            return (imageURL, imageData)
        } catch {
            logger.error("Cover art fetch error: \(error.localizedDescription)", category: .coverArt)
            return (nil, nil)
        }
    }

    // MARK: - Private

    private func fetchCoverArtInfo(releaseID: String) async throws -> CoverArtResponse {
        let urlString = "\(Constants.API.coverArtBaseURL)/release/\(releaseID)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(CoverArtResponse.self, from: data)
    }

    private func downloadImage(url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
