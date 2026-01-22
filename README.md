# Pulse

A professional-grade iOS/watchOS metronome featuring sub-millisecond audio timing precision, cross-platform haptic feedback, and a modern SwiftUI interface.

![Platform](https://img.shields.io/badge/platform-iOS%2017%2B%20%7C%20watchOS%2010%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![Architecture](https://img.shields.io/badge/architecture-MVVM%20%2B%20Observation-green)

## Overview

![Watch App](https://github.com/user-attachments/assets/e88b7260-df97-4be5-b877-8485bbd9a396)

Pulse solves a fundamental challenge in metronome development: **timing drift**. Standard iOS timers (`Timer`, `DispatchSourceTimer`) accumulate 10+ milliseconds of error after just 60 seconds due to run loop interference. For musicians, this drift is unacceptable.

This implementation achieves sample-accurate timing using AVAudioEngine's buffer scheduling system, maintaining sub-millisecond precision indefinitely.

## Technical Architecture

### Audio Engine: Sample-Accurate Timing

The core innovation is a drift-free timing system built on AVAudioEngine's buffer scheduling:

```
┌─────────────────────────────────────────────────────────────────┐
│                    AVAudioEngine Pipeline                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │   Buffer 1   │───▶│   Buffer 2   │───▶│   Buffer 3   │──┐    │
│  │  (Playing)   │    │  (Queued)    │    │  (Queued)    │  │    │
│  └──────────────┘    └──────────────┘    └──────────────┘  │    │
│         │                                                   │    │
│         ▼                                                   │    │
│  ┌──────────────┐                                          │    │
│  │  Completion  │◀─────────────────────────────────────────┘    │
│  │   Handler    │                                               │
│  └──────────────┘                                               │
│         │                                                        │
│         ▼                                                        │
│  ┌──────────────┐    ┌──────────────┐                           │
│  │Schedule Next │───▶│ Haptic/UI    │                           │
│  │   Buffer     │    │  Callback    │                           │
│  └──────────────┘    └──────────────┘                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Why this works:**

1. **Absolute Timing**: Each beat is calculated from the start time, not intervals: `startTime + (beatCount × interval)`. This eliminates cumulative drift.

2. **Pre-Scheduling**: Three buffers are always queued ahead. When buffer N completes playback, buffer N+3 is immediately scheduled.

3. **44.1kHz Precision**: Audio buffers are sized to exact sample counts. At 44,100 samples/second, timing resolution is ±0.023ms.

```swift
private func scheduleBeatsImmediate() {
    let beatInterval = 60.0 / Double(tempo)
    let buffer = createBeatBuffer(isAccented: isAccented, beatInterval: beatInterval)

    playerNode.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in
        self?.scheduleBeatsImmediate()  // Chain-schedule next buffer
    }
}
```

### Procedural Sound Synthesis

Click sounds are generated programmatically, eliminating audio file dependencies:

- **Regular beats**: 1000Hz sine wave with 50ms exponential decay
- **Accented beats**: 1200Hz sine wave with 50ms exponential decay
- **Envelope**: `amplitude × e^(-t/decay)` for natural transient response

```swift
private func createBeatBuffer(isAccented: Bool, beatInterval: TimeInterval) -> AVAudioPCMBuffer {
    let frequency: Float = isAccented ? 1200.0 : 1000.0
    let clickDuration: Float = 0.05  // 50ms

    for frame in 0..<clickFrames {
        let time = Float(frame) / Float(sampleRate)
        let envelope = exp(-time / (clickDuration * 0.3))  // Exponential decay
        let sample = sin(2.0 * .pi * frequency * time) * envelope * amplitude
        buffer[frame] = sample
    }

    // Remaining frames are silence until next beat
}
```

### Thread-Safe Concurrency Model

AVAudioEngine operates on dedicated real-time audio threads, requiring careful concurrency design:

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Main Thread   │     │  Audio Thread   │     │   UI Updates    │
│   (@MainActor)  │     │   (Real-time)   │     │                 │
├─────────────────┤     ├─────────────────┤     ├─────────────────┤
│                 │     │                 │     │                 │
│  ViewModel      │────▶│ MetronomeEngine │     │                 │
│  .start()       │     │ .start()        │     │                 │
│                 │     │                 │     │                 │
│                 │     │    ┌────────┐   │     │                 │
│                 │     │    │Buffer  │   │     │                 │
│                 │     │    │Complete│   │     │                 │
│                 │     │    └───┬────┘   │     │                 │
│                 │     │        │        │     │                 │
│                 │     │   onBeat()      │────▶│ Task @MainActor │
│                 │     │   callback      │     │ currentBeat = n │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

**Implementation with OSAllocatedUnfairLock:**

```swift
final class MetronomeEngine: Sendable {
    private struct State {
        var isPlaying = false
        var currentBeat = 0
        var beatsScheduled = 0
    }

    private let stateLock = OSAllocatedUnfairLock(initialState: State())

    func start(tempo: Int, beatsPerMeasure: Int, accentFirstBeat: Bool) {
        stateLock.withLock { state in
            state.isPlaying = true
            state.currentBeat = 0
        }
        scheduleBeats()
    }
}
```

This pattern ensures:
- Thread-safe state access from any context
- No `@MainActor` isolation on the engine (prevents deinit issues)
- Proper `Sendable` conformance for Swift 6 strict concurrency

### Cross-Platform Haptic Feedback

The haptic system abstracts platform differences while respecting hardware constraints:

| Platform | API | Downbeat | Regular Beat |
|----------|-----|----------|--------------|
| iOS | CoreHaptics | Intensity: 1.0, Sharpness: 1.0 | Intensity: 0.6, Sharpness: 0.8 |
| watchOS | WKInterfaceDevice | `.start` | `.click` |

**Critical constraint**: The Taptic Engine cannot play overlapping haptics. At 150 BPM (2.5 beats/sec) with 50ms haptic duration, there's a 350ms gap between events—safe margin for reliable playback.

```swift
#if os(iOS)
private func playiOSHaptic(isDownbeat: Bool) {
    let intensity = CHHapticEventParameter(
        parameterID: .hapticIntensity,
        value: isDownbeat ? 1.0 : 0.6
    )
    let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity], relativeTime: 0)
    try engine.makePlayer(with: CHHapticPattern(events: [event])).start(atTime: 0)
}
#elseif os(watchOS)
private func playwatchOSHaptic(isDownbeat: Bool) {
    WKInterfaceDevice.current().play(isDownbeat ? .start : .click)
}
#endif
```

### MVVM with Observation Framework

The architecture leverages iOS 17's Observation framework for efficient state management:

```swift
@Observable
@MainActor
final class MetronomeViewModel {
    var isPlaying: Bool = false
    var currentBeat: Int = 1
    var settings: MetronomeSettings

    @ObservationIgnored
    private var engine: MetronomeEngine?

    func start() {
        engine?.start(
            tempo: settings.tempo,
            beatsPerMeasure: settings.timeSignature.beatsPerMeasure,
            accentFirstBeat: settings.accentFirstBeat
        )
        isPlaying = true
    }
}
```

**Key decisions:**
- `@Observable` replaces `ObservableObject` with automatic change tracking
- `@MainActor` ensures all UI state mutations happen on the main thread
- `@ObservationIgnored` excludes the audio engine from observation (prevents unnecessary view updates)

## Project Structure

```
Pulse/
├── Shared/                           # Cross-platform code (~70%)
│   ├── Models/
│   │   ├── MetronomeSettings.swift   # Tempo, time signature, preferences
│   │   └── TimeSignature.swift       # Musical time signatures
│   ├── ViewModels/
│   │   └── MetronomeViewModel.swift  # @Observable state management
│   └── Services/
│       ├── MetronomeEngine.swift     # AVAudioEngine timing core
│       ├── HapticManager.swift       # Cross-platform haptics
│       └── AppGroupDefaults.swift    # Shared UserDefaults
│
├── Pulse/                            # iOS app
│   ├── Views/
│   │   ├── ContentView.swift
│   │   └── Components/               # BeatVisualizer, TempoControl, etc.
│   └── Pulse.entitlements
│
├── Pulse Watch App/                  # watchOS app
│   ├── Views/
│   │   ├── ContentView.swift         # TabView with Digital Crown
│   │   └── Components/
│   └── Pulse_Watch_App.entitlements
│
└── PulseTests/                       # Swift Testing framework
```

## Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Interaction                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     MetronomeViewModel                           │
│                        (@Observable)                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │  isPlaying  │  │ currentBeat │  │ settings: MetronomeSettings│
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
          │                   ▲                    │
          │                   │                    │
          ▼                   │                    ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│ MetronomeEngine  │  │   Beat Callback  │  │ AppGroupDefaults │
│  (AVAudioEngine) │──│  Task @MainActor │  │   (UserDefaults) │
└──────────────────┘  └──────────────────┘  └──────────────────┘
          │                                        │
          ▼                                        ▼
┌──────────────────┐                    ┌──────────────────┐
│  HapticManager   │                    │  Watch App Sync  │
│  (CoreHaptics)   │                    │   (App Groups)   │
└──────────────────┘                    └──────────────────┘
```

## Building

```bash
# iOS Simulator
xcodebuild -project Pulse.xcodeproj -scheme Pulse -sdk iphonesimulator build

# iOS Device
xcodebuild -project Pulse.xcodeproj -scheme Pulse -sdk iphoneos build

# watchOS
xcodebuild -project Pulse.xcodeproj -scheme "Pulse Watch App Watch App" -sdk watchos build
```

## Testing

Tests use Swift Testing framework (Xcode 16+):

```bash
xcodebuild test -project Pulse.xcodeproj -scheme Pulse \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

```swift
@Test("Tempo updates clamp to valid range")
func testTempoClamping() {
    let viewModel = MetronomeViewModel()
    viewModel.updateTempo(200)
    #expect(viewModel.settings.tempo == 150)  // Clamped to max
}
```

## Design Constraints

| Constraint | Value | Rationale |
|------------|-------|-----------|
| Min Tempo | 40 BPM | Musical practicality |
| Max Tempo | 150 BPM | Haptic engine rate limit (2.5 haptics/sec) |
| Sample Rate | 44.1kHz | Standard audio, ±0.023ms resolution |
| Buffer Reserve | 3 buffers | Prevents audio glitching |
| Click Duration | 50ms | Clear transient, no overlap at max tempo |

## Technologies

- **Swift 6** with strict concurrency checking
- **SwiftUI** with Observation framework
- **AVAudioEngine** for sample-accurate audio
- **CoreHaptics** (iOS) / WKInterfaceDevice (watchOS)
- **App Groups** for cross-device state sync
- **Swift Testing** for unit tests

## Requirements

- iOS 17.0+ / watchOS 10.0+
- Xcode 16.0+
- Swift 6.0+

## License

MIT License
