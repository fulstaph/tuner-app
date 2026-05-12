import Foundation
import SwiftData

@Model
final class Setlist {
    @Attribute(.unique) var id: UUID
    var name: String

    @Relationship var presets: [Preset]

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        presets: [Preset] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.presets = presets
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
