## 🔴 CI Failing: SwiftLint Violations (Job 74241245550)

The linting job is failing with 4 violations that must be fixed before merge. Here's the solution:

### Issues Found

1. **ToneGenerator.swift:5** — Line length: 136 characters (limit: 120)
2. **ToneGenerator.swift:25** — Line length: 130 characters (limit: 120)  
3. **MetronomeEngine.swift:28** — Function body length: 52 lines (limit: 50)
4. **AudioEngine.swift:38** — Line length: 166 characters (limit: 160)

---

### Fix 1: ToneGenerator.swift — Line 5

Split the function signature across multiple lines:

```swift
static func makeClickBuffer(
    frequency: Float,
    duration: Double,
    sampleRate: Double = 44100,
    gain: Float = 1.0
) -> AVAudioPCMBuffer {
```

---

### Fix 2: ToneGenerator.swift — Line 25

Split the long decay calculation:

```swift
let decayProgress = Float(i - attackSamples - sustainSamples) /
    Float(frameCount - attackSamples - sustainSamples)
```

---

### Fix 3: MetronomeEngine.swift — Function body (lines 28–88)

Extract the engine setup logic into a helper function to reduce the `start()` function from 52 lines to ~35:

```swift
private func setupAudioEngine(
    _ externalEngine: AVAudioEngine?,
    session: AVAudioSession
) -> AVAudioEngine {
    if let ext = externalEngine, ext.isRunning {
        borrowedEngine = ext
        ownedEngine = nil
        return ext
    } else {
        if session.category != .playAndRecord {
            try? session.setCategory(.playback, mode: .default)
            try? session.setActive(true)
        }
        let newEngine = AVAudioEngine()
        ownedEngine = newEngine
        borrowedEngine = nil
        return newEngine
    }
}
```

Then call it early in `start()`:

```swift
let engine = setupAudioEngine(externalEngine, session: session)
```

---

### Fix 4: AudioEngine.swift — Line 38

Split the long logging statement:

```swift
audioLog.info(
    "AudioEngine: category=\(session.category.rawValue, privacy: .public) " +
    "sampleRate=\(session.sampleRate) inputFormat=\(format, privacy: .public)"
)
```

---

**Once these changes are applied, the CI job should pass.** 🎯
