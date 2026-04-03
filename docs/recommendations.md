# Application Robustness & Improvement Recommendations

## Executive Summary

WhatsPlayin is a well-architected macOS music identification app built with SwiftUI, featuring a clean service-based design with pluggable recognition providers, real-time audio processing, and an AirPlay display mode. The codebase demonstrates solid separation of concerns and thoughtful use of modern Swift patterns.

However, the application has several critical issues that must be addressed before production use. The most severe is a crash that occurs after granting microphone permission, caused by CoreAudio returning invalid audio format data before the permission has fully propagated. The fingerprint generation uses a simplified proof-of-concept algorithm rather than the real Chromaprint library, meaning song identification will not work against the AcoustID database. Additionally, there is no test suite, no audio interruption handling, and thread safety violations in the logging system.

The top recommendations are: (1) integrate the real Chromaprint library for functional song identification, (2) add audio session interruption and device change handling for robustness, (3) persist track history across app launches, (4) consider ShazamKit integration as a primary or fallback provider, and (5) add comprehensive error recovery UI flows.

## Critical Fixes (Must Do)

### 1. Crash on Microphone Permission Grant (FIXED)
- **Root cause:** `AVAudioEngine.inputNode.outputFormat(forBus: 0)` returns 0 sampleRate / 0 channels immediately after permission grant, before CoreAudio configures the device.
- **Fix applied:** Format validation + retry logic with 0.5s delay between attempts (up to 3 retries).

### 2. Thread Safety in AppLogger (FIXED)
- **Root cause:** `@Published var debugEntries` was mutated from audio callback threads via NSLock, but `@Published` must fire Combine events on the main thread.
- **Fix applied:** Replaced NSLock with `DispatchQueue.main` dispatch.

### 3. Re-entrancy in Audio Setup (FIXED)
- **Root cause:** State remained `.idle` during permission dialog, allowing duplicate `setupAudioEngine()` calls.
- **Fix applied:** Added `.requestingPermission` state to block re-entrant calls.

### 4. Simplified Fingerprint Algorithm (NOT YET FIXED)
- **Impact:** The current `FingerprintService` uses an 8-subband energy analysis that produces fingerprints incompatible with AcoustID's Chromaprint-based database. Song identification will not return real results.
- **Required:** Link against `libchromaprint` via a bridging header, or use a Swift wrapper.

## Robustness Improvements (Should Do)

### Audio Interruption Handling
The app does not handle `AVAudioSession` interruptions (e.g., another app taking exclusive audio access, Bluetooth device disconnecting mid-capture). Competitors like Audio Hijack and Shazam gracefully pause and resume.

**Recommendation:** Subscribe to `AVAudioEngine.configurationChangeNotification` and `NSNotification.Name.AVAudioEngineConfigurationChange` to detect and recover from audio route changes. On interruption, stop the engine, wait for the interruption to end, then restart.

### Audio Device Change Handling
When the user switches between audio input devices (e.g., built-in mic to USB mic, or AirPods), the app should detect the change and reconfigure the audio engine.

**Recommendation:** Monitor `AVAudioSession.routeChangeNotification` and reinitialize the audio tap with the new device's format.

### Graceful Degradation on No Input Device
On Mac Mini or Mac Pro without built-in microphone and no external mic connected, `engine.inputNode` can throw an ObjC NSException.

**Recommendation:** Add a pre-check using `AVCaptureDevice.devices(for: .audio)` to verify at least one input device exists before attempting engine setup.

### Error Recovery UI
When the app enters an error state, the only recovery is restarting. Provide a "Retry" button that calls `startListening()` again.

## Feature Gaps vs Competitors

### vs Shazam (Apple)
| Feature | Shazam | WhatsPlayin | Priority |
|---------|--------|-------------|----------|
| ShazamKit recognition | Yes (proprietary) | No (AcoustID only) | High |
| Offline recognition | Yes (on-device catalog) | No | Medium |
| Music library integration | Apple Music, Spotify links | None | High |
| Widget support | Control Center, Widget | None | Medium |
| History sync via iCloud | Yes | No persistence at all | High |
| Haptic feedback on match | Yes | N/A (macOS) | Low |

### vs Audio Hijack (Rogue Amoeba)
| Feature | Audio Hijack | WhatsPlayin | Priority |
|---------|-------------|-------------|----------|
| Multi-source capture | Any app, any device | Microphone only | Low (different purpose) |
| Audio routing | Complex chains | Single input | Low |
| Format selection | Extensive | Fixed 11025Hz mono | Medium |
| Session recording | Yes | No | Low |
| Device hot-swap | Seamless | Not handled | High |

### vs SoundHound
| Feature | SoundHound | WhatsPlayin | Priority |
|---------|-----------|-------------|----------|
| Humming/singing recognition | Yes | No | Low |
| Real-time lyrics | Yes | No | Medium |
| Speed of recognition | < 3 seconds | Depends on buffer fill | Medium |
| Music streaming integration | Multiple services | None | Medium |

### Key Missing Features (Prioritized)
1. **Track history persistence** — History is lost on app quit. Use `UserDefaults`, `FileManager`, or `SwiftData` to persist.
2. **Music service links** — Add Apple Music / Spotify deep links for identified tracks.
3. **Menu bar mode** — Many macOS utilities live in the menu bar. This is natural for a "always listening" app.
4. **Keyboard shortcut** — Global hotkey for manual identification (like Shazam's).
5. **Export functionality** — Export history as CSV/JSON or share individual tracks.
6. **Notification on identification** — Push a macOS notification when a track is identified, especially useful in auto-detection mode.

## Architecture Recommendations

### 1. Protocol-Based Service Injection
Services are currently instantiated directly. Use protocol-based dependency injection to enable testing with mocks:
```swift
protocol AudioServiceProtocol: ObservableObject {
    var state: AudioServiceState { get }
    var currentLevel: Float { get }
    func startListening()
    func stopListening()
    func getBufferData() -> Data?
}
```

### 2. Structured Concurrency
Replace the `Timer`-based cooldown and countdown in `UIStateManager` with Swift structured concurrency (`AsyncStream`, `Task.sleep`). Timers are harder to test and can leak.

### 3. Separate Audio Capture from Audio Processing
The `AudioService` currently handles both capture and processing (downsampling, noise gate, normalization). Separating these would improve testability:
- `AudioCaptureService` — manages AVAudioEngine, produces raw buffers
- `AudioProcessor` — pure function that transforms buffers (testable without hardware)

### 4. State Machine Formalization
`AppState` and `AudioServiceState` manage transitions implicitly. Consider a formal state machine that validates transitions and prevents illegal states (e.g., going from `.idle` directly to `.identified`).

## Testing Gaps

### Currently Untestable Without Mocks
- **AudioService** — Requires real microphone hardware. Need protocol-based mock for `AVAudioEngine`.
- **RecognitionService** — Requires network + audio. Need mock providers and mock `AudioService`.
- **MetadataService** — Makes HTTP requests. Need `URLProtocol`-based mock or protocol abstraction.
- **CoverArtService** — Same as MetadataService.
- **UIStateManager** — Depends on `AudioService` and `RecognitionService`. Need injectable dependencies.

### Areas Needing Integration Tests
- Full pipeline: audio buffer → fingerprint → API → metadata → track display
- Permission flow: request → grant → audio starts → identification works
- Error recovery: permission denied → retry → grant → works
- Auto-detection loop: timer fires → identifies → cooldown → next identification

### UI Testing
- No snapshot tests or UI tests exist
- SwiftUI previews could serve as visual regression baseline
- Accessibility labels are missing on interactive elements

## macOS Platform Best Practices

### 1. Use @MainActor Consistently
`UIStateManager` is `@MainActor` but `AudioService` is not. All `ObservableObject` classes that drive UI should use `@MainActor` or carefully dispatch all `@Published` mutations.

### 2. Handle Audio Session Categories (macOS)
macOS 14+ supports `AVAudioApplication.requestRecordPermission()` as the preferred permission API over `AVCaptureDevice.requestAccess(for: .audio)`.

### 3. Adopt App Intents
For Shortcuts and Siri integration, adopt `AppIntents` framework:
- "Identify current song" shortcut
- "Show track history" shortcut

### 4. Support Dark/Light Mode Properly
The app uses `.ultraThinMaterial` which adapts well, but explicit color choices in `AirPlayNowPlayingView` (hardcoded `.white`, `.black`) don't adapt to system appearance.

### 5. Keyboard Navigation
macOS apps should fully support keyboard navigation. Add `keyboardShortcut` modifiers to buttons (e.g., `Command+L` for Listen, `Command+I` for Identify).

### 6. Accessibility
- Add `accessibilityLabel` to status indicators and the confidence progress bar
- Ensure VoiceOver can navigate the full UI
- Support Dynamic Type where possible

## Prioritised Action Plan

| # | Action | Effort | Impact |
|---|--------|--------|--------|
| 1 | Integrate libchromaprint for real fingerprinting | Medium | Critical — app doesn't work without it |
| 2 | Persist track history (SwiftData or JSON file) | Small | High — data lost on every quit |
| 3 | Add audio interruption & device change handling | Small | High — prevents crashes during use |
| 4 | Add protocol-based DI for testability | Medium | High — enables comprehensive testing |
| 5 | Add menu bar mode | Medium | High — natural UX for macOS utility |
| 6 | Integrate ShazamKit as primary/fallback provider | Medium | High — superior recognition accuracy |
| 7 | Add Apple Music / Spotify deep links | Small | Medium — improves utility |
| 8 | Add global keyboard shortcut for identification | Small | Medium — power user feature |
| 9 | Add macOS notifications on track identification | Small | Medium — useful in auto-detect mode |
| 10 | Add error recovery UI ("Retry" button) | Small | Medium — better error UX |
| 11 | Export history as CSV/JSON | Small | Low — nice to have |
| 12 | Add App Intents / Shortcuts support | Medium | Low — platform integration |
| 13 | Add snapshot / UI tests | Medium | Low — code quality |
| 14 | Adopt `AVAudioApplication.requestRecordPermission()` for macOS 14+ | Small | Low — future-proofing |
