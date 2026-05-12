import Foundation
import SwiftData
@testable import Tuner

enum PersistenceTestHelpers {
    @MainActor
    static func makeInMemoryContainer() -> ModelContainer {
        let schema = Schema([
            Preset.self,
            Setlist.self,
            PracticeSession.self,
            TuningSnapshot.self,
            EarTrainingSession.self,
            ExerciseResult.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        return try! ModelContainer(for: schema, configurations: [config])
    }

    static func makeEphemeralDefaults(suiteName: String = "tuner.tests.\(UUID().uuidString)") -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @MainActor
    static func seedDefaultPreset(in context: ModelContext) -> Preset {
        let preset = Preset(name: "Default", sortOrder: 0)
        context.insert(preset)
        try? context.save()
        return preset
    }
}
