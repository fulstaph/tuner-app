# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iOS chromatic tuner app built with SwiftUI (iOS 17+, Swift 5.9). Detects pitch from the device microphone, displays the nearest note name with cent deviation, and supports transposing instruments. Uses XcodeGen (`project.yml`) to generate the Xcode project.

## Build & Test Commands

```bash
# Regenerate Xcode project from project.yml (after adding/removing files)
xcodegen generate

# Build
xcodebuild -scheme Tuner -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run all unit tests
xcodebuild -scheme Tuner -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run a specific test class
xcodebuild -scheme Tuner -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:TunerTests/PitchDetectorTests test

# Run a specific test method
xcodebuild -scheme Tuner -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:TunerTests/PitchDetectorTests/testDetect440Hz test

# Run UI tests only
xcodebuild -scheme Tuner -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:TunerUITests test
```

## Architecture

MVVM with a unidirectional audio pipeline:

```
Microphone → AudioEngine → [Float] buffer → PitchDetector → frequency → NoteMapper → TunerData → Views
```

- **AudioEngine** (`Tuner/Audio/AudioEngine.swift`): Wraps AVAudioEngine, delivers raw Float buffers via `onBuffer` callback. Conforms to `AudioEngineProtocol` for testability.
- **PitchDetector** (`Tuner/Audio/PitchDetector.swift`): YIN autocorrelation using Accelerate/vDSP. Pure computation, no dependencies. Returns frequency + confidence.
- **NoteMapper** (`Tuner/Core/NoteMapper.swift`): Frequency → 12-TET note mapping with transposition offset. Static enum, no state.
- **TunerViewModel** (`Tuner/ViewModels/TunerViewModel.swift`): `@Observable` class owning the pipeline. Applies smoothing (EMA) and note debouncing to reduce jitter. Persists settings to UserDefaults.
- **Views** switch on `TunerStyle` enum to render one of three display styles (needle gauge, linear bar, minimalist).

## Key Design Decisions

- The `AudioEngineProtocol` abstraction exists solely for unit testing — `MockAudioEngine` in tests can inject known sine-wave buffers without a real microphone.
- Note debouncing requires 3 consecutive matching frames before updating the displayed note, preventing flicker between adjacent notes.
- Smoothing uses an exponential moving average (factor 0.3) on the cent value.
- Settings are stored in UserDefaults directly (not @AppStorage) because the ViewModel is `@Observable` not an `ObservableObject`.

## Testing

Unit tests use `TestHelpers.generateSineWave(frequency:)` to create known audio buffers. The `MockAudioEngine.simulateBuffer(_:)` method injects buffers into the pipeline without needing audio hardware. ViewModel tests are `@MainActor` and use `Task.sleep` to allow async dispatch to complete.
