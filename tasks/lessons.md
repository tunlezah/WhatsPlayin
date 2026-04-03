# Lessons Learned — WhatsPlayin

## 1. AVAudioEngine.inputNode format validation is mandatory on macOS

**Pattern:** After a fresh microphone permission grant, `inputNode.outputFormat(forBus: 0)` 
can return a zeroed format (sampleRate=0, channelCount=0) because CoreAudio hasn't 
propagated the permission to the audio subsystem yet.

**Rule:** Always validate `sampleRate > 0` and `channelCount > 0` before using 
`inputNode.outputFormat()`. Implement retry logic with a short delay (0.5s) to allow 
CoreAudio to catch up.

## 2. @Published properties must only be mutated from the main thread

**Pattern:** `AppLogger` used NSLock to guard `@Published var debugEntries` modifications 
from any thread. But `@Published` emits Combine `objectWillChange` notifications that must 
originate from the property's owning thread (main thread for ObservableObject). Mutating 
from a background thread causes Combine/SwiftUI crashes.

**Rule:** Always dispatch `@Published` mutations to `DispatchQueue.main` when the mutation 
could originate from a background thread. Use `Thread.isMainThread` check to avoid 
unnecessary dispatches.

## 3. State machines need re-entrancy guards

**Pattern:** `AudioService.startListening()` guarded on `state == .idle`, but the state 
remained `.idle` during the entire permission dialog flow. Multiple calls could trigger 
multiple `setupAudioEngine()` invocations.

**Rule:** Transition state immediately when entering an async operation (e.g., 
`.requestingPermission`) so that re-entrant calls are rejected by the state guard.

## 4. Environment limitations affect verification

**Pattern:** This session runs on Linux without Xcode/Swift toolchain. Cannot compile or 
run tests directly.

**Rule:** Write tests that are structurally correct and will compile on macOS. Document 
that build verification requires macOS with Xcode 16+.
