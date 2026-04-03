# WhatsPlayin — Crash Fix, Robustness Audit & Competitive Analysis

## Phase 1: Crash Investigation (Microphone Access)

- [x] Explore entire codebase and understand architecture
- [x] Identify crash root cause in AudioService.setupAudioEngine()
- [x] Fix 1: Validate audio input format before use (sampleRate > 0, channelCount > 0)
- [x] Fix 2: Prevent re-entrancy in startListening() with `.requestingPermission` state
- [x] Fix 3: Add retry logic for transient audio system unavailability after permission grant
- [x] Fix 4: Validate downsampleRatio is finite and positive
- [x] Fix 5: Fix thread safety in AppLogger (@Published dispatched to main thread)
- [x] Fix 6: Clean up tap on engine.start() failure
- [x] Update UIStateManager to handle new `.requestingPermission` state

## Phase 2: Robustness Audit — Testing & Stub Detection

### Test Suite (9 test files, 60+ test cases)
- [x] TrackTests — initialization, computed properties, equality, Codable round-trip
- [x] IdentificationResultTests — isValid logic with nil/zero edge cases
- [x] AcoustIDResponseTests — JSON decoding (valid, empty, error)
- [x] MusicBrainzRecordingResponseTests — JSON decoding with/without releases
- [x] CoverArtResponseTests — JSON decoding with thumbnails, empty images
- [x] FingerprintServiceTests — empty data, too short, valid audio, different hashes, duration, sample rate
- [x] DuplicateDetectionServiceTests — first detection, identical hash, cooldown, reset, per-track
- [x] AudioServiceTests — initial state, buffer data, silence, stop safety
- [x] AppStateTests — statusText, equality for all cases
- [x] ConstantsTests — valid ranges for all constants, valid URLs
- [x] StubProviderTests — returns nil, protocol conformance
- [x] LoggerTests — log entry levels, categories, singleton, clear entries
- [x] Add XCTest target to Xcode project (WhatsPlayinTests)
- [x] Update scheme to include test target

### Stub & Incomplete Implementation Audit

| # | Location | Description | Severity | Status |
|---|----------|-------------|----------|--------|
| 1 | `StubProvider.swift` | Entire class is a placeholder — always returns nil. Intended as extension point for ShazamKit. | **Medium** | Documented. By design — fallback provider pattern. No crash risk since nil is handled. |
| 2 | `FingerprintService.swift:38` | Uses simplified spectral analysis instead of real Chromaprint/libchromaprint. | **High** | Documented. Works for structure but produces fingerprints incompatible with AcoustID's database. Real identification requires linking libchromaprint. |
| 3 | `FingerprintService.swift:56-92` | `computeSimplifiedFingerprint` — 8-subband energy analysis is a proof-of-concept, not production-grade. | **High** | Same as #2. Functional but won't match songs in AcoustID. |

### Other Code Quality Findings

| # | Location | Description | Severity | Fixed? |
|---|----------|-------------|----------|--------|
| 4 | `AudioService.swift:101-123` | No format validation → crash on 0 sampleRate/channels | **Critical** | **YES** |
| 5 | `AudioService.swift:30-36` | No re-entrancy guard during permission request | **Critical** | **YES** |
| 6 | `Logger.swift:50-63` | @Published mutated from background thread via NSLock | **Critical** | **YES** |
| 7 | `AudioService.swift` | No audio interruption handling (other apps taking audio) | **Medium** | Documented |
| 8 | `AudioService.swift` | No audio device change notification handling | **Medium** | Documented |
| 9 | `UIStateManager.swift` | Track history not persisted to disk | **Low** | Documented |
| 10 | `RecognitionService.swift:136` | `identifyNow()` called from non-MainActor context in auto-detection | **Medium** | Documented — works because `identifyNow()` is `@MainActor` and awaited |

### No TODO/FIXME/HACK markers found in code
Zero explicit stub markers. All incomplete implementations are documented with descriptive
comments explaining what production use would require.

## Phase 3: Competitive Research & Recommendations

- [x] Research written to `docs/recommendations.md`

---

## Root Cause Analysis

### Crash: Post-Microphone-Permission Grant

**Location:** `AudioService.swift:101-123` (`setupAudioEngine()`)

**Signal:** EXC_BAD_ACCESS or SIGABRT (depending on exact failure path)

**Root Cause:** Three interacting defects:

1. **Invalid audio format from inputNode** — After granting microphone permission,
   `inputNode.outputFormat(forBus: 0)` returns a format with `sampleRate == 0` and
   `channelCount == 0` because CoreAudio hasn't finished configuring the input device.
   This causes `installTap(format:)` to crash with an AVFAudio internal exception, and
   `downsampleRatio` to be 0 (causing infinite loop in audio processing).

2. **No re-entrancy protection** — `startListening()` guards on `state == .idle`, but
   state remained `.idle` during the entire permission dialog. Multiple calls could trigger
   duplicate `setupAudioEngine()` invocations, installing duplicate taps → crash.

3. **Thread safety violation in logger** — `@Published var debugEntries` was mutated under
   NSLock from any thread (including audio callback). `@Published` fires Combine events
   that must originate on the main thread. Audio processing → logging → Combine crash.

### Fix Applied

1. Added `.requestingPermission` state to `AudioServiceState` — prevents re-entrant calls
2. Added format validation (`sampleRate > 0, channelCount > 0`) before using inputFormat
3. Added `setupAudioEngineWithRetry()` with up to 3 retry attempts (0.5s delay each) to
   handle transient post-permission-grant delay
4. Added `downsampleRatio` sanity check (finite and positive)
5. Clean up tap on `engine.start()` failure
6. Replaced NSLock-guarded @Published mutation with `DispatchQueue.main` dispatch in Logger
