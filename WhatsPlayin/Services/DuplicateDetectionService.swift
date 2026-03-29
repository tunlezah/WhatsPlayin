import Foundation

/// Prevents duplicate detections using fingerprint similarity and per-track cooldowns
final class DuplicateDetectionService {
    private let settings: AppSettings
    private let logger = AppLogger.shared

    private var lastFingerprintHash: String?
    private var lastDetectionTime: Date?
    private var trackCooldowns: [String: Date] = [] // trackKey -> lastDetectedAt

    /// Remaining global cooldown seconds (for UI countdown)
    var remainingCooldown: TimeInterval {
        guard let last = lastDetectionTime else { return 0 }
        let elapsed = Date().timeIntervalSince(last)
        return max(0, settings.cooldownDuration - elapsed)
    }

    var isInCooldown: Bool {
        remainingCooldown > 0
    }

    init(settings: AppSettings = .shared) {
        self.settings = settings
    }

    /// Check if a detection should be suppressed
    /// - Parameters:
    ///   - fingerprintHash: Hash of the new fingerprint
    ///   - result: The identification result
    /// - Returns: true if detection should proceed, false if suppressed
    func shouldAccept(fingerprintHash: String, result: IdentificationResult?) -> Bool {
        // Check global cooldown
        if isInCooldown {
            logger.info("Suppressed: global cooldown active (\(Int(remainingCooldown))s remaining)", category: .recognition)
            return false
        }

        // Check fingerprint similarity
        if let lastHash = lastFingerprintHash, lastHash == fingerprintHash {
            logger.info("Suppressed: identical fingerprint hash", category: .recognition)
            return false
        }

        // Check per-track cooldown
        if let result = result, let title = result.title, let artist = result.artist {
            let trackKey = "\(title.lowercased())|\(artist.lowercased())"
            if let lastTrackTime = trackCooldowns[trackKey] {
                let elapsed = Date().timeIntervalSince(lastTrackTime)
                if elapsed < settings.perTrackCooldown {
                    logger.info("Suppressed: per-track cooldown for '\(title)' (\(Int(settings.perTrackCooldown - elapsed))s remaining)", category: .recognition)
                    return false
                }
            }
        }

        return true
    }

    /// Record a successful detection
    func recordDetection(fingerprintHash: String, result: IdentificationResult) {
        lastFingerprintHash = fingerprintHash
        lastDetectionTime = Date()

        if let title = result.title, let artist = result.artist {
            let trackKey = "\(title.lowercased())|\(artist.lowercased())"
            trackCooldowns[trackKey] = Date()
        }

        // Clean old cooldowns
        let cutoff = Date().addingTimeInterval(-settings.perTrackCooldown * 2)
        trackCooldowns = trackCooldowns.filter { $0.value > cutoff }
    }

    /// Reset all cooldown state
    func reset() {
        lastFingerprintHash = nil
        lastDetectionTime = nil
        trackCooldowns.removeAll()
    }
}
