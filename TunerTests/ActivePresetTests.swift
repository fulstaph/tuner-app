import SwiftData
import XCTest
@testable import Tuner

final class ActivePresetTests: XCTestCase {
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
    func testResolveReturnsNilWhenNoPresetsExist() {
        XCTAssertNil(ActivePreset.resolve(in: context, defaults: defaults))
    }

    @MainActor
    func testResolveByStoredID() throws {
        let preset = Preset(name: "Stored")
        context.insert(preset)
        try context.save()
        ActivePreset.setID(preset.id, in: defaults)

        let resolved = try XCTUnwrap(ActivePreset.resolve(in: context, defaults: defaults))
        XCTAssertEqual(resolved.id, preset.id)
    }

    @MainActor
    func testResolveFallsBackToFirstBySortOrderAndPersistsID() throws {
        let second = Preset(name: "Second", sortOrder: 1)
        let first = Preset(name: "First", sortOrder: 0)
        context.insert(second)
        context.insert(first)
        try context.save()

        let resolved = try XCTUnwrap(ActivePreset.resolve(in: context, defaults: defaults))
        XCTAssertEqual(resolved.name, "First")
        XCTAssertEqual(ActivePreset.id(in: defaults), first.id)
    }

    @MainActor
    func testSetIDNilClearsValue() {
        ActivePreset.setID(UUID(), in: defaults)
        ActivePreset.setID(nil, in: defaults)
        XCTAssertNil(ActivePreset.id(in: defaults))
    }
}
