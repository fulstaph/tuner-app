import SwiftData
import XCTest
@testable import Tuner

final class PresetCRUDTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    @MainActor
    override func setUp() {
        super.setUp()
        container = PersistenceTestHelpers.makeInMemoryContainer()
        context = container.mainContext
    }

    @MainActor
    override func tearDown() {
        context = nil
        container = nil
        super.tearDown()
    }

    @MainActor
    func testInsertAndFetchPreset() throws {
        let preset = Preset(name: "Jazz", bpm: 140, timeSignature: .threeFour)
        context.insert(preset)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Preset>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Jazz")
        XCTAssertEqual(fetched.first?.bpm, 140)
        XCTAssertEqual(fetched.first?.timeSignature, .threeFour)
    }

    @MainActor
    func testUpdatePresetPersists() throws {
        let preset = Preset(name: "Default")
        context.insert(preset)
        try context.save()

        preset.bpm = 200
        preset.tunerStyle = .minimalist
        try context.save()

        let fetched = try XCTUnwrap(try context.fetch(FetchDescriptor<Preset>()).first)
        XCTAssertEqual(fetched.bpm, 200)
        XCTAssertEqual(fetched.tunerStyle, .minimalist)
    }

    @MainActor
    func testDeletePreset() throws {
        let preset = Preset(name: "Temp")
        context.insert(preset)
        try context.save()

        context.delete(preset)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Preset>()), 0)
    }

    @MainActor
    func testSetlistOrdersPresets() throws {
        let a = Preset(name: "A", sortOrder: 0)
        let b = Preset(name: "B", sortOrder: 1)
        let c = Preset(name: "C", sortOrder: 2)
        let setlist = Setlist(name: "Gig", presets: [a, b, c])
        context.insert(setlist)
        try context.save()

        let fetched = try XCTUnwrap(try context.fetch(FetchDescriptor<Setlist>()).first)
        XCTAssertEqual(fetched.presets.map(\.name), ["A", "B", "C"])
    }

    @MainActor
    func testCustomTuningRoundTrips() throws {
        let tuning = CustomTuning(
            instrumentName: "Open D",
            notes: [
                TuningNote(noteName: "D", octave: 2, centOffset: nil),
                TuningNote(noteName: "A", octave: 2, centOffset: 0),
                TuningNote(noteName: "D", octave: 3, centOffset: -2.5)
            ]
        )
        let preset = Preset(name: "Slide", customTuning: tuning)
        context.insert(preset)
        try context.save()

        let fetched = try XCTUnwrap(try context.fetch(FetchDescriptor<Preset>()).first)
        XCTAssertEqual(fetched.customTuning?.instrumentName, "Open D")
        XCTAssertEqual(fetched.customTuning?.notes.count, 3)
        XCTAssertEqual(fetched.customTuning?.notes.last?.centOffset, -2.5)
    }

    @MainActor
    func testTempoRampRoundTrips() throws {
        let preset = Preset(
            name: "Ramp",
            tempoRamp: TempoRamp(bpmIncrease: 5, everyNBars: 4, maxBPM: 180)
        )
        context.insert(preset)
        try context.save()

        let fetched = try XCTUnwrap(try context.fetch(FetchDescriptor<Preset>()).first)
        XCTAssertEqual(fetched.tempoRamp?.bpmIncrease, 5)
        XCTAssertEqual(fetched.tempoRamp?.everyNBars, 4)
        XCTAssertEqual(fetched.tempoRamp?.maxBPM, 180)
    }

    @MainActor
    func testPracticeSessionCascadeDeletesSnapshots() throws {
        let snapshot = TuningSnapshot(
            noteName: "A",
            octave: 4,
            centsDeviation: -3.0,
            frequency: 439.0
        )
        let session = PracticeSession(type: .tuning, tuningSnapshots: [snapshot])
        context.insert(session)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<TuningSnapshot>()), 1)

        context.delete(session)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<TuningSnapshot>()), 0)
    }

    @MainActor
    func testEarTrainingSessionCascadeDeletesResults() throws {
        let result = ExerciseResult(
            playedNote: "C",
            playedInterval: .perfect5th,
            userAnswer: "G",
            correct: true,
            responseTimeSeconds: 1.2
        )
        let session = EarTrainingSession(
            exerciseType: .intervalIdentification,
            results: [result]
        )
        context.insert(session)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ExerciseResult>()), 1)

        context.delete(session)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ExerciseResult>()), 0)
    }

    @MainActor
    func testDefaultAccentPatternMatchesTimeSignature() {
        let four = Preset.defaultAccentPattern(for: .fourFour)
        XCTAssertEqual(four.count, 4)
        XCTAssertEqual(four.first, .strong)

        let seven = Preset.defaultAccentPattern(for: .sevenEight)
        XCTAssertEqual(seven.count, 7)
    }
}
