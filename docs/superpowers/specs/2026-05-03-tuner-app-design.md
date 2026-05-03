# Tuner iOS App — Design Spec

## Context

A native iOS tuner application built with SwiftUI. Musicians need a reliable, low-latency chromatic tuner that shows the detected pitch, nearest note name, and cent deviation. The app supports transposing instruments (Bb, Eb, F, A) so players see note names matching their sheet music. Three visual styles (needle gauge, linear bar, minimalist text) are selectable in settings.

## Scope

### In Scope
- Real-time pitch detection from device microphone
- Chromatic tuner displaying frequency, note name, octave, and cent deviation
- Three tuner display styles, switchable in settings
- Transposing instrument presets
- Adjustable reference pitch (A4 = 415–460 Hz, default 440)

### Out of Scope
- Custom transposition intervals (beyond presets)
- Tone generator / metronome
- Recording or history
- Android / cross-platform

## Architecture

MVVM pattern with clear separation between audio processing and UI.

### Data Flow

```
Microphone → AudioEngine → [Float] → PitchDetector → Hz → NoteMapper → TunerData
                                                                            ↓
                                                                    TunerViewModel
                                                                    ↓     ↓     ↓
                                                    NeedleGaugeView  LinearBarView  MinimalistView
```

### Components

#### AudioEngine
- Wraps `AVAudioEngine`
- Installs an input node tap, delivers raw `Float` audio buffers
- Handles microphone permission request (`AVAudioSession`)
- Sample rate: 44,100 Hz
- Buffer size: 4096 samples (~93ms latency)

#### PitchDetector
- Implements YIN autocorrelation algorithm using Accelerate framework (`vDSP`)
- Parabolic interpolation for sub-bin frequency accuracy
- Detection range: C1 (32 Hz) – C8 (4186 Hz)
- Returns detected frequency and a confidence value (0.0–1.0)
- Confidence threshold filters out silence and noise

#### NoteMapper
- Converts frequency to nearest 12-TET note using: `noteNumber = 12 * log2(freq / referencePitch) + 69`
- Cent deviation: fractional part of noteNumber × 100
- Note names: `["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]`
- Applies transposition offset (semitone shift) before mapping noteNumber to name

#### TunerData
Published struct consumed by views:
- `frequency: Double` — detected frequency in Hz
- `note: String` — nearest note name (e.g. "A")
- `octave: Int` — octave number (e.g. 4)
- `cents: Double` — deviation from nearest note (-50 to +50)
- `isActive: Bool` — whether a pitch is currently detected

#### TunerViewModel
- `@Observable` class, owns AudioEngine + PitchDetector + NoteMapper
- Publishes `TunerData` for views to observe
- Reads settings from `@AppStorage`
- Starts/stops audio engine on view appear/disappear

#### Settings
Persisted via `@AppStorage`:
- `tunerStyle: TunerStyle` — enum: `.needle`, `.linearBar`, `.minimalist`
- `instrumentPreset: InstrumentPreset` — enum with associated semitone offset
- `referencePitch: Double` — default 440.0 Hz

## Transposing Instrument Presets

| Preset | Instruments | Semitone Shift |
|---|---|---|
| Concert Pitch (C) | Flute, Piano, Violin | 0 |
| B♭ | Clarinet, Trumpet, Tenor Sax | +2 |
| E♭ | Alto Sax, Baritone Sax | -3 |
| F | French Horn, English Horn | +7 |
| A | Oboe d'amore | +3 |

Transposition shifts the displayed note name so it matches what the musician reads. The underlying detected frequency is unchanged.

## Tuner Display Styles

### Needle Gauge
Semicircular dial with tick marks at cent intervals. A needle swings left (flat) to right (sharp) around a center "in tune" mark. Note name and frequency shown below the dial.

### Linear Bar
Horizontal track with a sliding indicator dot. Center mark = in tune, left = flat, right = sharp. Note name displayed prominently above, cent readout below.

### Minimalist Text
Typography-driven layout. Large note name + octave centered on screen, frequency in smaller monospace text below. Cent deviation as a signed number with "sharp"/"flat" label. Subtle dot strip indicating position.

## UI Behavior

- **Smoothing:** Needle/bar/dot movement is dampened to avoid jitter from frame-to-frame frequency fluctuation
- **Color coding:** Green when within ±5 cents of in tune, orange otherwise
- **Debouncing:** Note name only updates when a new pitch is confidently detected for a few consecutive frames — prevents flickering between adjacent notes
- **No signal state:** When mic input is below threshold or silent, display shows a muted/inactive state rather than random values
- **Microphone permission:** Prompt on first launch; show an informative state if denied
- **Display adaptability:** All tuner views must scale across iPhone screen sizes (SE through Pro Max). Needle gauge and linear bar use relative sizing (percentages / `GeometryReader`) rather than fixed dimensions. Text sizes adapt using SwiftUI Dynamic Type where appropriate. Landscape orientation is not a priority for v1 — portrait-only is acceptable.

## App Structure

```
TunerApp (entry point)
├── ContentView
│   ├── TunerDisplayView (switches on tunerStyle setting)
│   │   ├── NeedleGaugeView
│   │   ├── LinearBarView
│   │   └── MinimalistView
│   └── Navigation to SettingsView
└── SettingsView
    ├── Tuner Style picker
    ├── Instrument Preset picker
    └── Reference Pitch slider
```

## Testing Strategy

### Unit Tests
- **PitchDetector:** Feed known sine wave buffers (e.g. 440 Hz, 261.63 Hz), assert detected frequency is within ±1 Hz
- **NoteMapper:** Verify Hz → note/octave/cents mapping for exact frequencies (A4=440→"A",4,0 cents), sharp cases (445 Hz → "A",4,~+20 cents), flat cases (435 Hz → "A",4,~-20 cents), boundary cases (between two notes)
- **NoteMapper transposition:** Verify each instrument preset shifts note names correctly (e.g. concert B♭ at 466.16 Hz with B♭ preset → displays "C")
- **NoteMapper reference pitch:** Verify changing reference from 440 to 442 shifts cent calculations appropriately
- **TunerData:** Verify struct initialization and edge values (cents clamped to ±50, isActive toggling)

### Integration Tests
- **AudioEngine → PitchDetector pipeline:** Verify that audio buffers flow through to produce a frequency result (can use injected test buffers rather than live mic)
- **TunerViewModel:** Verify that settings changes (style, instrument, reference pitch) propagate correctly to published state

### UI Tests
- Verify all three display styles render without crashes
- Verify settings screen controls update persisted values
- Verify style switching shows the correct tuner view

## Verification

1. Build and run on iOS Simulator (note: mic input may not work on simulator — test on device or with audio injection)
2. Verify pitch detection accuracy against a known tone generator (e.g. 440 Hz sine → should show A4, 0 cents)
3. Confirm all three display styles render correctly and switch properly
4. Confirm transposition shifts note names correctly (e.g. play concert Bb, set to "Bb instrument" → should display C)
5. Confirm reference pitch adjustment shifts cent readings (e.g. set to 442 Hz, play 440 Hz → should show A4, slightly flat)
6. Verify no-signal state displays correctly when silent
7. Verify microphone permission flow
