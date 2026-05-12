import Foundation
import SwiftData

enum UserDefaultsMigrator {
    @discardableResult
    static func migrateIfNeeded(
        context: ModelContext,
        defaults: UserDefaults = .standard
    ) -> Preset? {
        if defaults.bool(forKey: PersistenceKeys.hasMigratedToSwiftData) {
            return ActivePreset.resolve(in: context, defaults: defaults)
        }

        let storedTunerStyle = defaults.string(forKey: PersistenceKeys.Legacy.tunerStyle)
            .flatMap(TunerStyle.init(rawValue:)) ?? .needle

        let storedInstrument = defaults.string(forKey: PersistenceKeys.Legacy.instrumentPreset)
            .flatMap(InstrumentPreset.init(rawValue:)) ?? .concert

        let storedPitchRaw = defaults.double(forKey: PersistenceKeys.Legacy.referencePitch)
        let storedPitch = storedPitchRaw > 0 ? storedPitchRaw : 440.0

        let storedBPMRaw = defaults.integer(forKey: PersistenceKeys.Legacy.metronomeBPM)
        let storedBPM = storedBPMRaw > 0 ? storedBPMRaw : 120

        let storedTimeSignature = defaults.string(forKey: PersistenceKeys.Legacy.metronomeTimeSignature)
            .flatMap(TimeSignature.init(rawValue:)) ?? .fourFour

        let storedMetronomeStyle = defaults.string(forKey: PersistenceKeys.Legacy.metronomeStyle)
            .flatMap(MetronomeStyle.init(rawValue:)) ?? .minimal

        let preset = Preset(
            name: "Default",
            bpm: storedBPM,
            timeSignature: storedTimeSignature,
            referencePitch: storedPitch,
            instrumentPreset: storedInstrument,
            tunerStyle: storedTunerStyle,
            metronomeStyle: storedMetronomeStyle,
            sortOrder: 0
        )

        context.insert(preset)
        do {
            try context.save()
        } catch {
            return nil
        }

        ActivePreset.setID(preset.id, in: defaults)

        for key in PersistenceKeys.Legacy.all {
            defaults.removeObject(forKey: key)
        }
        defaults.set(true, forKey: PersistenceKeys.hasMigratedToSwiftData)

        return preset
    }
}
