import Foundation
import SwiftData

enum ActivePreset {
    static func id(in defaults: UserDefaults = .standard) -> UUID? {
        guard let raw = defaults.string(forKey: PersistenceKeys.activePresetID) else {
            return nil
        }
        return UUID(uuidString: raw)
    }

    static func setID(_ id: UUID?, in defaults: UserDefaults = .standard) {
        if let id {
            defaults.set(id.uuidString, forKey: PersistenceKeys.activePresetID)
        } else {
            defaults.removeObject(forKey: PersistenceKeys.activePresetID)
        }
    }

    static func resolve(
        in context: ModelContext,
        defaults: UserDefaults = .standard
    ) -> Preset? {
        if let id = id(in: defaults), let preset = fetch(id: id, in: context) {
            return preset
        }

        let descriptor = FetchDescriptor<Preset>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        )
        let preset = (try? context.fetch(descriptor))?.first
        if let preset {
            setID(preset.id, in: defaults)
        }
        return preset
    }

    private static func fetch(id: UUID, in context: ModelContext) -> Preset? {
        var descriptor = FetchDescriptor<Preset>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }
}
