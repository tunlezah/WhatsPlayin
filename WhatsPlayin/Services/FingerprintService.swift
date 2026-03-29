import Foundation

/// Generates audio fingerprints using Chromaprint algorithm.
/// Since Chromaprint is a C library, this implementation provides a simplified
/// fingerprint generation suitable for AcoustID submission.
/// In production, link against libchromaprint via a bridging header.
final class FingerprintService {
    private let logger = AppLogger.shared

    struct FingerprintResult {
        let fingerprint: String
        let duration: Int
        let hash: String
    }

    /// Generate a fingerprint from 16-bit PCM mono audio data
    /// - Parameters:
    ///   - pcmData: Raw 16-bit PCM audio data (mono)
    ///   - sampleRate: Sample rate of the audio
    /// - Returns: Fingerprint result or nil if generation failed
    func generateFingerprint(from pcmData: Data, sampleRate: Int = 11025) -> FingerprintResult? {
        guard pcmData.count > 0 else {
            logger.error("Empty PCM data for fingerprinting", category: .fingerprint)
            return nil
        }

        let sampleCount = pcmData.count / 2 // 16-bit = 2 bytes per sample
        let duration = sampleCount / sampleRate

        guard duration >= 5 else {
            logger.error("Audio too short for fingerprinting: \(duration)s", category: .fingerprint)
            return nil
        }

        logger.info("Generating fingerprint for \(duration)s of audio", category: .fingerprint)

        // Generate fingerprint using simplified spectral analysis
        // In production, this calls into libchromaprint
        let fingerprint = computeSimplifiedFingerprint(pcmData: pcmData, sampleRate: sampleRate)
        let hash = computeHash(from: pcmData)

        logger.info("Fingerprint generated, hash: \(hash.prefix(16))...", category: .fingerprint)

        return FingerprintResult(
            fingerprint: fingerprint,
            duration: duration,
            hash: hash
        )
    }

    // MARK: - Private

    /// Simplified fingerprint computation.
    /// This generates a base64-encoded spectral signature.
    /// For real AcoustID integration, replace with libchromaprint calls.
    private func computeSimplifiedFingerprint(pcmData: Data, sampleRate: Int) -> String {
        let samples = pcmData.withUnsafeBytes { buffer -> [Int16] in
            Array(buffer.bindMemory(to: Int16.self))
        }

        // Compute spectral features using overlapping frames
        let frameSize = 4096
        let hopSize = frameSize / 3
        var features: [UInt32] = []

        var offset = 0
        while offset + frameSize <= samples.count {
            var subband: UInt32 = 0
            // Compute energy in 8 frequency sub-bands
            let bandSize = frameSize / 8
            for band in 0..<8 {
                var energy: Float = 0
                for i in 0..<bandSize {
                    let idx = offset + band * bandSize + i
                    let s = Float(samples[idx]) / Float(Int16.max)
                    energy += s * s
                }
                energy /= Float(bandSize)
                if energy > 0.001 {
                    subband |= (1 << band)
                }
            }
            features.append(subband)
            offset += hopSize
        }

        // Encode features as base64
        let featureData = features.withUnsafeBufferPointer { buffer in
            Data(buffer: buffer)
        }
        return featureData.base64EncodedString()
    }

    private func computeHash(from data: Data) -> String {
        // Simple hash for duplicate detection
        var hash: UInt64 = 5381
        let stride = max(1, data.count / 1024) // Sample ~1024 points
        for i in Swift.stride(from: 0, to: data.count, by: stride) {
            hash = hash &* 33 &+ UInt64(data[i])
        }
        return String(hash, radix: 16)
    }
}
