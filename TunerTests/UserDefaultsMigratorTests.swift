import SwiftData
import XCTest
@testable import Tuner

final class UserDefaultsMigratorTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var defaults: UserDefaults!
    var suiteName: String!

    @MainActor
    override func setUp() {
        super.setUp()
        container = PersistenceTestHelpers.makeInMemoryContainer()
        context = container.mainContext
        suiteName = "tuner.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        context = nil
        container = nil
        super.tearDown()
    }

    @MainActor
    func testMigratesSeededLegacyValuesIntoDefaultPreset() throws {
        defaults.set("linearBar", forKey: PersistenceKeys.Legacy.tunerStyle)
        defaults.set("bFlat", forKey: PersistenceKeys.Legacy.instrumentPreset)
        defaults.set(442.0, forKey: PersistenceKeys.Legacy.referencePitch)
        defaults.set(160, forKey: PersistenceKeys.Legacy.metronomeBPM)
        defaults.set("7/8", forKey: PersistenceKeys.Legacy.metronomeTimeSignature)
        defaults.set("circularGauge", forKey: PersistenceKeys.Legacy.metronomeStyle)

        let preset = UserDefaultsMigrator.migrateIfNeeded(context: context, defaults: defaults)

        let migrated = try XCTUnwrap(preset)
        XCTAssertEqual(migrated.name, "Default")
        XCTAssertEqual(migrated.tunerStyle, .linearBar)
        XCTAssertEqual(migrated.instrumentPreset, .bFlat)
        XCTAssertEqual(migrated.referencePitch, 442.0)
        XCTAssertEqual(migrated.bpm, 160)
        XCTAssertEqual(migrated.timeSignature, .sevenEight)
        XCTAssertEqual(migrated.metronomeStyle, .circularGauge)
        XCTAssertEqual(migrated.accentPattern.count, 7)
    }

    @MainActor
    func testMigrationSetsActivePresetIDAndFlag() throws {
        _ = UserDefaultsMigrator.migrateIfNeeded(context: context, defaults: defaults)

        XCTAssertTrue(defaults.bool(forKey: PersistenceKeys.hasMigratedToSwiftData))
        XCTAssertNotNil(ActivePreset.id(in: defaults))
    }

    @MainActor
    func testMigrationClearsLegacyKeys() throws {
        defaults.set("needle", forKey: PersistenceKeys.Legacy.tunerStyle)
        defaults.set("concert", forKey: PersistenceKeys.Legacy.instrumentPreset)
        defaults.set(440.0, forKey: PersistenceKeys.Legacy.referencePitch)

        _ = UserDefaultsMigrator.migrateIfNeeded(context: context, defaults: defaults)

        for key in PersistenceKeys.Legacy.all {
            XCTAssertNil(defaults.object(forKey: key), "Expected legacy key \(key) to be cleared")
        }
    }

    @MainActor
    func testMigrationUsesDefaultsWhenLegacyKeysMissing() throws {
        let preset = try XCTUnwrap(
            UserDefaultsMigrator.migrateIfNeeded(context: context, defaults: defaults)
        )
        XCTAssertEqual(preset.tunerStyle, .needle)
        XCTAssertEqual(preset.instrumentPreset, .concert)
        XCTAssertEqual(preset.referencePitch, 440.0)
        XCTAssertEqual(preset.bpm, 120)
        XCTAssertEqual(preset.timeSignature, .fourFour)
        XCTAssertEqual(preset.metronomeStyle, .minimal)
    }

    @MainActor
    func testMigrationIsIdempotent() throws {
        _ = UserDefaultsMigrator.migrateIfNeeded(context: context, defaults: defaults)
        _ = UserDefaultsMigrator.migrateIfNeeded(context: context, defaults: defaults)
        _ = UserDefaultsMigrator.migrateIfNeeded(context: context, defaults: defaults)

        let descriptor = FetchDescriptor<Preset>()
        let count = try context.fetchCount(descriptor)
        XCTAssertEqual(count, 1)
    }

    @MainActor
    func testSecondInvocationReturnsExistingPreset() throws {
        let first = try XCTUnwrap(
            UserDefaultsMigrator.migrateIfNeeded(context: context, defaults: defaults)
        )
        let second = try XCTUnwrap(
            UserDefaultsMigrator.migrateIfNeeded(context: context, defaults: defaults)
        )
        XCTAssertEqual(first.id, second.id)
    }
}
