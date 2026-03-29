import Foundation

enum Constants {
    enum Audio {
        static let defaultSampleRate: Double = 11025
        static let highSampleRate: Double = 44100
        static let channelCount: UInt32 = 1 // Mono
        static let bitDepth: UInt32 = 16
        static let minBufferDuration: Double = 10
        static let maxBufferDuration: Double = 30
        static let defaultBufferDuration: Double = 20
        static let noiseGateThreshold: Float = 0.01
    }

    enum Detection {
        static let defaultInterval: TimeInterval = 120
        static let minInterval: TimeInterval = 30
        static let maxInterval: TimeInterval = 300
        static let defaultConfidenceThreshold: Double = 0.6
        static let defaultCooldownDuration: TimeInterval = 30
        static let defaultPerTrackCooldown: TimeInterval = 300
        static let silenceThreshold: Float = 0.005
        static let silenceDuration: TimeInterval = 2.0
    }

    enum History {
        static let maxTracks = 10
    }

    enum API {
        static let acoustIDBaseURL = "https://api.acoustid.org/v2/lookup"
        static let musicBrainzBaseURL = "https://musicbrainz.org/ws/2"
        static let coverArtBaseURL = "https://coverartarchive.org"
        static let musicBrainzUserAgent = "WhatsPlayin/1.0 (https://github.com/tunlezah/whatsplayin)"
        static let musicBrainzRateLimit: TimeInterval = 1.0
    }
}
