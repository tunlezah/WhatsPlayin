import SwiftUI

struct MainView: View {
    @StateObject private var stateManager = UIStateManager()
    @State private var showSettings = false
    @State private var showAirPlayWindow = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("WhatsPlayin")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                StatusIndicator(
                    state: stateManager.appState,
                    cooldownRemaining: stateManager.cooldownRemaining,
                    nextDetection: stateManager.nextDetectionCountdown
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // Now Playing
            NowPlayingView(track: stateManager.currentTrack)
                .padding(.vertical, 16)

            Divider()

            // Controls
            HStack(spacing: 12) {
                Button(action: { stateManager.toggleListening() }) {
                    Label(
                        isListening ? "Stop" : "Start",
                        systemImage: isListening ? "stop.circle.fill" : "mic.circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .tint(isListening ? .red : .accentColor)

                Button(action: { stateManager.identifyManually() }) {
                    Label("Identify", systemImage: "waveform.badge.magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.bordered)
                .disabled(!isListening || stateManager.recognitionService.isProcessing)

                Button(action: { showSettings.toggle() }) {
                    Image(systemName: "gear")
                }
                .controlSize(.large)
                .buttonStyle(.bordered)

                Button(action: { showAirPlayWindow.toggle() }) {
                    Image(systemName: "airplayvideo")
                }
                .controlSize(.large)
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // History
            HistoryView(tracks: stateManager.history)
                .frame(maxHeight: 200)

            // Debug (if enabled)
            if stateManager.settings.debugModeEnabled {
                Divider()
                DebugView(
                    audioService: stateManager.audioService,
                    recognitionService: stateManager.recognitionService,
                    duplicateService: stateManager.recognitionService.duplicateDetection
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
        .frame(width: 400, height: stateManager.settings.debugModeEnabled ? 780 : 580)
        .background(.ultraThinMaterial)
        .popover(isPresented: $showSettings) {
            SettingsView(settings: stateManager.settings)
        }
        .sheet(isPresented: $showAirPlayWindow) {
            AirPlayNowPlayingView(
                currentTrack: stateManager.currentTrack,
                recentTracks: Array(stateManager.history.prefix(3))
            )
            .frame(minWidth: 800, minHeight: 600)
        }
    }

    private var isListening: Bool {
        switch stateManager.appState {
        case .idle, .error: return false
        default: return true
        }
    }
}
