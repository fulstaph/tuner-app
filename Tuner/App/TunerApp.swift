import SwiftData
import SwiftUI

@main
struct TunerApp: App {
    private let container: ModelContainer
    private let tunerViewModel: TunerViewModel
    private let metronomeViewModel: MetronomeViewModel

    init() {
        let container = Self.makeSharedContainer()
        UserDefaultsMigrator.migrateIfNeeded(context: container.mainContext)
        self.container = container

        let context = container.mainContext
        let activePreset = ActivePreset.resolve(in: context)
        self.tunerViewModel = TunerViewModel(modelContext: context, activePreset: activePreset)
        self.metronomeViewModel = MetronomeViewModel(modelContext: context, activePreset: activePreset)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                tunerViewModel: tunerViewModel,
                metronomeViewModel: metronomeViewModel
            )
            .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }

    private static func makeSharedContainer() -> ModelContainer {
        let schema = Schema([
            Preset.self,
            Setlist.self,
            PracticeSession.self,
            TuningSnapshot.self,
            EarTrainingSession.self,
            ExerciseResult.self
        ])
        let configuration = ModelConfiguration(schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
