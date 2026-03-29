import Foundation
import Combine
import SwiftUI

enum AppState: Equatable {
    case idle
    case listening
    case processing
    case identified(Track)
    case coolingDown
    case error(String)

    var statusText: String {
        switch self {
        case .idle: return "Ready"
        case .listening: return "Listening…"
        case .processing: return "Processing…"
        case .identified: return "Identified"
        case .coolingDown: return "Cooling down"
        case .error(let msg): return "Error: \(msg)"
        }
    }

    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.listening, .listening), (.processing, .processing), (.coolingDown, .coolingDown):
            return true
        case (.identified(let a), .identified(let b)):
            return a == b
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

@MainActor
final class UIStateManager: ObservableObject {
    @Published var appState: AppState = .idle
    @Published var currentTrack: Track?
    @Published var history: [Track] = []
    @Published var cooldownRemaining: TimeInterval = 0
    @Published var nextDetectionCountdown: TimeInterval = 0

    let audioService: AudioService
    let recognitionService: RecognitionService
    let settings: AppSettings

    private var cancellables = Set<AnyCancellable>()
    private var cooldownTimer: Timer?
    private var countdownTimer: Timer?
    private var lastDetectionTime: Date?

    init(settings: AppSettings = .shared) {
        self.settings = settings
        self.audioService = AudioService(settings: settings)
        self.recognitionService = RecognitionService(audioService: audioService, settings: settings)

        observeAudioState()
    }

    // MARK: - Actions

    func startListening() {
        audioService.startListening()
        if settings.autoDetectionEnabled {
            startAutoDetection()
        }
    }

    func stopListening() {
        audioService.stopListening()
        recognitionService.stopAutoDetection()
        stopTimers()
        appState = .idle
    }

    func identifyManually() {
        Task {
            appState = .processing
            if let track = await recognitionService.identifyNow() {
                handleNewTrack(track)
            } else {
                appState = .listening
            }
        }
    }

    func toggleListening() {
        switch appState {
        case .idle, .error:
            startListening()
        default:
            stopListening()
        }
    }

    // MARK: - Private

    private func observeAudioState() {
        audioService.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .idle:
                    if case .listening = self.appState {} else {
                        self.appState = .idle
                    }
                case .listening:
                    self.appState = .listening
                case .error(let msg):
                    self.appState = .error(msg)
                }
            }
            .store(in: &cancellables)
    }

    private func startAutoDetection() {
        lastDetectionTime = Date()
        startCountdownTimer()

        recognitionService.startAutoDetection { [weak self] track in
            self?.handleNewTrack(track)
        }
    }

    private func handleNewTrack(_ track: Track) {
        currentTrack = track
        appState = .identified(track)

        // Add to history
        history.insert(track, at: 0)
        if history.count > Constants.History.maxTracks {
            history.removeLast()
        }

        // Start cooldown
        startCooldownTimer()
        lastDetectionTime = Date()
    }

    private func startCooldownTimer() {
        cooldownRemaining = settings.cooldownDuration
        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.cooldownRemaining = self.recognitionService.duplicateDetection.remainingCooldown
                if self.cooldownRemaining > 0 {
                    self.appState = .coolingDown
                } else {
                    self.cooldownTimer?.invalidate()
                    if case .listening = self.audioService.state {
                        self.appState = .listening
                    }
                }
            }
        }
    }

    private func startCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if let last = self.lastDetectionTime {
                    let elapsed = Date().timeIntervalSince(last)
                    self.nextDetectionCountdown = max(0, self.settings.detectionInterval - elapsed)
                }
            }
        }
    }

    private func stopTimers() {
        cooldownTimer?.invalidate()
        cooldownTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        cooldownRemaining = 0
        nextDetectionCountdown = 0
    }
}
