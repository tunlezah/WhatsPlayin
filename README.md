# WhatsPlayin

A native macOS application that listens to music via microphone, identifies songs using audio fingerprinting, and displays a "Now Playing" interface — locally and via AirPlay.

![macOS](https://img.shields.io/badge/macOS-15%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Audio Capture** — Continuous microphone listening with real-time level monitoring
- **Song Identification** — AcoustID fingerprinting + MusicBrainz metadata resolution
- **Album Artwork** — Automatic cover art from the Cover Art Archive
- **Smart Re-detection** — Duplicate prevention with configurable per-track and global cooldowns
- **Auto/Manual Modes** — Configurable automatic scanning interval or on-demand identification
- **Gap Detection** — Optional silence-based track transition detection
- **Now Playing Display** — Clean SwiftUI interface with album art, track info, and confidence indicator
- **AirPlay Support** — Full-screen Now Playing view for Apple TV via AirPlay screen casting
- **History** — Last 10 identified tracks with thumbnails
- **Debug Mode** — Real-time audio levels, buffer state, fingerprint logs, and API responses
- **Fully Configurable** — Buffer length, detection interval, confidence threshold, cooldowns, and more

## Architecture

```
WhatsPlayin/
├── App/                    # App entry point
├── Models/                 # Data models (Track, IdentificationResult, AppSettings)
├── Services/               # Business logic
│   ├── AudioService        # Microphone capture via AVAudioEngine
│   ├── FingerprintService  # Audio fingerprint generation (Chromaprint-compatible)
│   ├── RecognitionService  # Orchestrates the full identification pipeline
│   ├── MetadataService     # MusicBrainz metadata enrichment
│   ├── CoverArtService     # Cover Art Archive artwork fetching
│   ├── DuplicateDetection  # Fingerprint hashing + cooldown management
│   └── Providers/          # Pluggable recognition providers
│       ├── AcoustIDProvider
│       └── StubProvider    # Placeholder for future providers (e.g., ShazamKit)
├── ViewModels/             # UIStateManager (app state coordination)
├── Views/                  # SwiftUI views
│   ├── MainView            # Primary app window
│   ├── NowPlayingView      # Current track display
│   ├── HistoryView         # Track history list
│   ├── SettingsView        # User preferences
│   ├── DebugView           # Debug panel
│   ├── AirPlayNowPlayingView # Full-screen AirPlay display
│   └── Components/         # Reusable UI components
└── Utilities/              # Constants, Logger
```

## Requirements

- **macOS 15.0+** (Sequoia or later)
- **Xcode 16+**
- **AcoustID API Key** (free)

## Setup

### 1. Get an AcoustID API Key

1. Go to [AcoustID](https://acoustid.org/)
2. Create an account and register a new application
3. Copy your API key

### 2. Clone and Build

```bash
git clone https://github.com/tunlezah/whatsplayin.git
cd whatsplayin
open WhatsPlayin.xcodeproj
```

### 3. Configure API Key

1. Launch the app
2. Click the gear icon (Settings)
3. Enter your AcoustID API key in the "API Configuration" section

### 4. Grant Microphone Permission

On first launch, macOS will prompt for microphone access. Click **Allow**.

If you accidentally denied access:
1. Open **System Settings** > **Privacy & Security** > **Microphone**
2. Enable WhatsPlayin

### 5. AirPlay Setup

To display the Now Playing screen on an Apple TV:

1. Click the AirPlay icon in the app
2. The full-screen Now Playing view opens in a separate window
3. Use macOS **Screen Mirroring** (Control Center) to send that window to your Apple TV
4. Alternatively, drag the window to an AirPlay display

## Usage

1. **Start Listening** — Click "Start" to begin capturing audio
2. **Identify** — Click "Identify" for manual recognition, or enable auto-detection in Settings
3. **View Results** — Track info, artwork, and confidence appear in the Now Playing area
4. **History** — Previously identified tracks appear in the history list below
5. **AirPlay** — Click the AirPlay button to open the full-screen display

## Settings

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| Buffer Duration | 20s | 10-30s | Audio buffer length for fingerprinting |
| Detection Interval | 120s | 30-300s | Time between automatic identifications |
| Confidence Threshold | 60% | 10-100% | Minimum confidence to accept a result |
| Cooldown Duration | 30s | 10-120s | Global cooldown after each detection |
| Per-Track Cooldown | 300s | 60-600s | Cooldown before re-detecting the same track |
| Auto Detection | On | - | Enable/disable automatic scanning |
| Gap Detection | Off | - | Detect silence-based track transitions |
| Fallback Provider | On | - | Try fallback provider on low confidence |
| Debug Mode | Off | - | Show debug panel with audio/API details |

## API Services

| Service | Key Required | Notes |
|---------|-------------|-------|
| [AcoustID](https://acoustid.org/) | Yes (free) | Audio fingerprint lookup |
| [MusicBrainz](https://musicbrainz.org/) | No | Metadata (rate-limited to 1 req/s) |
| [Cover Art Archive](https://coverartarchive.org/) | No | Album artwork |

## Provider System

WhatsPlayin uses a pluggable provider architecture:

```swift
protocol MusicRecognitionProvider {
    func identify(audioData: Data) async -> IdentificationResult?
}
```

- **AcoustIDProvider** — Primary provider using AcoustID + Chromaprint
- **StubProvider** — Placeholder for future integrations (e.g., ShazamKit)

To add a new provider, implement the `MusicRecognitionProvider` protocol and register it in `RecognitionService`.

## License

MIT License — see [LICENSE](LICENSE) for details.
