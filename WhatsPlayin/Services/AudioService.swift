import AVFoundation
import Combine

enum AudioServiceState {
    case idle
    case requestingPermission
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

    /// Maximum number of retries when audio format is invalid after permission grant
    private static let maxSetupRetries = 3
    /// Delay between setup retries to allow CoreAudio to propagate permission
    private static let setupRetryDelay: UInt64 = 500_000_000 // 0.5s in nanoseconds

    private var targetSampleRate: Double { Constants.Audio.defaultSampleRate }
    private var maxBufferSamples: Int {
        Int(settings.bufferDuration * targetSampleRate)
    }

    init(settings: AppSettings = .shared) {
        self.settings = settings
    }

    func startListening() {
        switch state {
        case .idle, .error:
            break // Allowed to start
        case .requestingPermission, .listening:
            return // Already in progress
        }

        guard checkMicrophonePermission() else {
            requestMicrophonePermission()
            return
        }
        setupAudioEngine()
    }

    func stopListening() {
        if let engine = audioEngine {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
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
        state = .requestingPermission
        logger.info("Requesting microphone permission", category: .audio)

        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                guard let self = self else { return }
                // Only proceed if we're still in the requestingPermission state
                // (user hasn't cancelled or triggered something else)
                guard case .requestingPermission = self.state else { return }

                if granted {
                    self.logger.info("Microphone permission granted", category: .audio)
                    self.setupAudioEngineWithRetry()
                } else {
                    self.state = .error("Microphone access denied. Please enable in System Settings > Privacy & Security > Microphone.")
                    self.logger.error("Microphone permission denied", category: .audio)
                }
            }
        }
    }

    /// Attempts to set up the audio engine with retries to handle the case where
    /// CoreAudio hasn't finished configuring the input device after permission grant.
    private func setupAudioEngineWithRetry(attempt: Int = 0) {
        guard attempt < Self.maxSetupRetries else {
            state = .error("Could not access audio input device. Please check System Settings and restart the app.")
            logger.error("Audio engine setup failed after \(Self.maxSetupRetries) attempts", category: .audio)
            return
        }

        if attempt > 0 {
            logger.info("Retrying audio engine setup (attempt \(attempt + 1)/\(Self.maxSetupRetries))", category: .audio)
        }

        let setupResult = setupAudioEngine()

        if case .needsRetry = setupResult {
            // CoreAudio hasn't propagated the permission yet — retry after a short delay
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: Self.setupRetryDelay)
                self.setupAudioEngineWithRetry(attempt: attempt + 1)
            }
        }
    }

    private enum SetupResult {
        case success
        case failed
        case needsRetry
    }

    private func setupAudioEngine() -> SetupResult {
        let engine = AVAudioEngine()

        // On macOS, accessing inputNode can throw an ObjC NSException if no audio
        // input device is available. We validate the format to detect this case safely.
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        logger.info("Input format: \(inputFormat.sampleRate)Hz, \(inputFormat.channelCount)ch", category: .audio)

        // Validate format: after a fresh permission grant, CoreAudio may not have
        // configured the input device yet, returning 0 sampleRate / 0 channels.
        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
            logger.error("Invalid input format (sampleRate=\(inputFormat.sampleRate), channels=\(inputFormat.channelCount))", category: .audio)
            return .needsRetry
        }

        let downsampleRatio = inputFormat.sampleRate / targetSampleRate

        // Sanity check: downsampleRatio must be positive and finite
        guard downsampleRatio.isFinite, downsampleRatio > 0 else {
            logger.error("Invalid downsample ratio: \(downsampleRatio)", category: .audio)
            return .needsRetry
        }

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer, downsampleRatio: downsampleRatio)
        }

        do {
            try engine.start()
            audioEngine = engine
            state = .listening
            logger.info("Audio engine started at \(targetSampleRate)Hz target", category: .audio)
            return .success
        } catch {
            inputNode.removeTap(onBus: 0)
            state = .error("Failed to start audio engine: \(error.localizedDescription)")
            logger.error("Audio engine start failed: \(error)", category: .audio)
            return .failed
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
