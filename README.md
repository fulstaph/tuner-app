# Tuner

A native iOS chromatic tuner built with SwiftUI. Detects pitch in real time from the device microphone and displays the nearest note, octave, and cent deviation.

## Features

- Real-time pitch detection using YIN autocorrelation (Accelerate/vDSP)
- Three display styles: Needle Gauge, Linear Bar, Minimalist
- Transposing instrument presets (Concert, B♭, E♭, F, A)
- Adjustable reference pitch (A4 = 415–460 Hz)
- Detection range: C1 (32 Hz) – C8 (4186 Hz)

## Requirements

- iOS 17.0+
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Setup

```bash
brew install xcodegen
xcodegen generate
open Tuner.xcodeproj
```

## Running Tests

```bash
xcodebuild -scheme Tuner -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Architecture

MVVM with a unidirectional audio pipeline:

```
Microphone → AudioEngine → PitchDetector → NoteMapper → TunerViewModel → Views
```

The audio layer is protocol-abstracted (`AudioEngineProtocol`) for unit testing without hardware.
