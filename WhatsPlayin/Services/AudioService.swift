import AVFoundation
import Combine

enum AudioServiceState {
    case idle
    case listening
    case error(String)
}

final class AudioService: ObservableObject {
    @Published private(set) var state: AudioServiceState = .idle
    @Published private(set) var currentLevel: Float = 0
    @Published private(set) var bufferFillPercent: Double = 0

    private var audioEngine: AVAudioEngine?
    private var rollingBuffer: [Float] = []
    private let settings: AppSettings
    private let logger = AppLogger.shared
    private let lock = NSLock()

    private var targetSampleRate: Double { Constants.Audio.defaultSampleRate }
    private var maxBufferSamples: Int {
        Int(settings.bufferDuration * targetSampleRate)
    }

    init(settings: AppSettings = .shared) {
        self.settings = settings
    }

    func startListening() {
        guard case .idle = state else { return }
        guard checkMicrophonePermission() else {
            requestMicrophonePermission()
            return
        }
        setupAudioEngine()
    }

    func stopListening() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        state = .idle
        lock.lock()
        rollingBuffer.removeAll()
        lock.unlock()
        bufferFillPercent = 0
        currentLevel = 0
        logger.info("Stopped listening", category: .audio)
    }

    /// Returns current buffer as 16-bit PCM mono data at target sample rate
    func getBufferData() -> Data? {
        lock.lock()
        let samples = rollingBuffer
        lock.unlock()

        guard !samples.isEmpty else { return nil }

        var data = Data(capacity: samples.count * 2)
        for sample in samples {
            let clamped = max(-1.0, min(1.0, sample))
            var int16Sample = Int16(clamped * Float(Int16.max))
            data.append(Data(bytes: &int16Sample, count: 2))
        }
        return data
    }

    /// Returns the duration of the current buffer in seconds
    var bufferDurationSeconds: Double {
        lock.lock()
        let count = rollingBuffer.count
        lock.unlock()
        return Double(count) / targetSampleRate
    }

    /// Detects if the current audio level indicates silence
    var isSilent: Bool {
        currentLevel < Constants.Detection.silenceThreshold
    }

    // MARK: - Private

    private func checkMicrophonePermission() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }

    private func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.setupAudioEngine()
                } else {
                    self?.state = .error("Microphone access denied. Please enable in System Settings > Privacy & Security > Microphone.")
                    self?.logger.error("Microphone permission denied", category: .audio)
                }
            }
        }
    }

    private func setupAudioEngine() {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        logger.info("Input format: \(inputFormat.sampleRate)Hz, \(inputFormat.channelCount)ch", category: .audio)

        let downsampleRatio = inputFormat.sampleRate / targetSampleRate

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer, downsampleRatio: downsampleRatio)
        }

        do {
            try engine.start()
            audioEngine = engine
            state = .listening
            logger.info("Audio engine started at \(targetSampleRate)Hz target", category: .audio)
        } catch {
            state = .error("Failed to start audio engine: \(error.localizedDescription)")
            logger.error("Audio engine start failed: \(error)", category: .audio)
        }
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, downsampleRatio: Double) {
        guard let channelData = buffer.floatChannelData else { return }

        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)

        // Mix to mono and downsample
        var monoSamples: [Float] = []
        monoSamples.reserveCapacity(Int(Double(frameCount) / downsampleRatio) + 1)

        var rmsSum: Float = 0
        var sampleIndex: Double = 0

        while Int(sampleIndex) < frameCount {
            let idx = Int(sampleIndex)
            var sample: Float = 0
            for ch in 0..<channelCount {
                sample += channelData[ch][idx]
            }
            sample /= Float(channelCount)

            // Noise gate
            if abs(sample) < Constants.Audio.noiseGateThreshold {
                sample = 0
            }

            rmsSum += sample * sample
            monoSamples.append(sample)
            sampleIndex += downsampleRatio
        }

        // Calculate RMS level
        let rms = monoSamples.isEmpty ? 0 : sqrt(rmsSum / Float(monoSamples.count))

        // Normalize peak
        let peak = monoSamples.map { abs($0) }.max() ?? 0
        if peak > 0.001 {
            let normFactor = min(1.0 / peak, 10.0) // Cap normalization
            for i in monoSamples.indices {
                monoSamples[i] *= normFactor
            }
        }

        // Append to rolling buffer
        lock.lock()
        rollingBuffer.append(contentsOf: monoSamples)
        let overflow = rollingBuffer.count - maxBufferSamples
        if overflow > 0 {
            rollingBuffer.removeFirst(overflow)
        }
        let fill = Double(rollingBuffer.count) / Double(maxBufferSamples)
        lock.unlock()

        DispatchQueue.main.async { [weak self] in
            self?.currentLevel = rms
            self?.bufferFillPercent = fill
        }
    }
}
