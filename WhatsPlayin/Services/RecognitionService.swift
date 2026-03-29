import Foundation
import Combine

/// Orchestrates the full recognition pipeline: audio → fingerprint → identify → metadata → artwork
final class RecognitionService: ObservableObject {
    @Published private(set) var isProcessing = false

    private let audioService: AudioService
    private let metadataService: MetadataService
    private let coverArtService: CoverArtService
    private let duplicateService: DuplicateDetectionService
    private let settings: AppSettings
    private let logger = AppLogger.shared

    private var primaryProvider: MusicRecognitionProvider
    private var fallbackProvider: MusicRecognitionProvider?

    private var autoDetectionTask: Task<Void, Never>?

    init(
        audioService: AudioService,
        settings: AppSettings = .shared,
        metadataService: MetadataService = MetadataService(),
        coverArtService: CoverArtService = CoverArtService(),
        duplicateService: DuplicateDetectionService = DuplicateDetectionService()
    ) {
        self.audioService = audioService
        self.settings = settings
        self.metadataService = metadataService
        self.coverArtService = coverArtService
        self.duplicateService = duplicateService
        self.primaryProvider = AcoustIDProvider(settings: settings)
        self.fallbackProvider = StubProvider()
    }

    var duplicateDetection: DuplicateDetectionService { duplicateService }

    /// Perform a single identification attempt
    @MainActor
    func identifyNow() async -> Track? {
        guard !isProcessing else {
            logger.info("Already processing, skipping", category: .recognition)
            return nil
        }

        guard let audioData = audioService.getBufferData() else {
            logger.error("No audio data available", category: .recognition)
            return nil
        }

        isProcessing = true
        defer { isProcessing = false }

        logger.info("Starting identification (\(audioService.bufferDurationSeconds)s buffer)", category: .recognition)

        // Try primary provider
        var result = await primaryProvider.identify(audioData: audioData)

        // Try fallback if needed
        if settings.fallbackProviderEnabled,
           let fallback = fallbackProvider,
           (result == nil || (result?.confidence ?? 0) < settings.confidenceThreshold) {
            logger.info("Primary provider failed/low confidence, trying fallback", category: .recognition)
            result = await fallback.identify(audioData: audioData)
        }

        guard let result = result, result.isValid else {
            logger.info("No valid identification result", category: .recognition)
            return nil
        }

        // Check duplicate detection
        guard duplicateService.shouldAccept(fingerprintHash: result.fingerprintHash, result: result) else {
            return nil
        }

        // Enrich with metadata
        let enriched = await metadataService.enrichResult(result)

        // Fetch cover art
        var artworkURL: URL? = nil
        var artworkData: Data? = nil
        if let releaseID = enriched.musicBrainzReleaseID {
            let artwork = await coverArtService.fetchArtwork(releaseID: releaseID)
            artworkURL = artwork.url
            artworkData = artwork.data
        }

        // Record detection for duplicate prevention
        duplicateService.recordDetection(fingerprintHash: result.fingerprintHash, result: enriched)

        let track = Track(
            title: enriched.title ?? "Unknown",
            artist: enriched.artist ?? "Unknown",
            album: enriched.album,
            releaseYear: enriched.releaseYear,
            musicBrainzID: enriched.musicBrainzRecordingID,
            confidence: enriched.confidence,
            artworkURL: artworkURL,
            artworkData: artworkData
        )

        logger.info("Identified: \(track.displayTitle) (\(track.confidencePercent)%)", category: .recognition)
        return track
    }

    /// Start automatic detection loop
    func startAutoDetection(onTrackDetected: @escaping (Track) -> Void) {
        stopAutoDetection()

        autoDetectionTask = Task { [weak self] in
            guard let self = self else { return }

            while !Task.isCancelled {
                // Wait for detection interval
                try? await Task.sleep(nanoseconds: UInt64(self.settings.detectionInterval * 1_000_000_000))

                guard !Task.isCancelled else { break }
                guard self.settings.autoDetectionEnabled else { continue }

                // Gap detection: wait for silence then new audio
                if self.settings.gapDetectionEnabled && self.audioService.isSilent {
                    self.logger.debug("Gap detected, waiting for new audio...", category: .recognition)
                    // Wait until not silent or timeout
                    var waited: TimeInterval = 0
                    while self.audioService.isSilent && waited < 10 && !Task.isCancelled {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                        waited += 0.5
                    }
                }

                if self.duplicateService.isInCooldown {
                    continue
                }

                if let track = await self.identifyNow() {
                    await MainActor.run {
                        onTrackDetected(track)
                    }
                }
            }
        }

        logger.info("Auto-detection started (interval: \(settings.detectionInterval)s)", category: .recognition)
    }

    func stopAutoDetection() {
        autoDetectionTask?.cancel()
        autoDetectionTask = nil
        logger.info("Auto-detection stopped", category: .recognition)
    }
}
