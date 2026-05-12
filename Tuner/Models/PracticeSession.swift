import Foundation
import SwiftData

@Model
final class PracticeSession {
    @Attribute(.unique) var id: UUID

    @Relationship var preset: Preset?

    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: Int
    var type: SessionType

    @Relationship(deleteRule: .cascade) var tuningSnapshots: [TuningSnapshot]

    init(
        id: UUID = UUID(),
        preset: Preset? = nil,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        durationSeconds: Int = 0,
        type: SessionType,
        tuningSnapshots: [TuningSnapshot] = []
    ) {
        self.id = id
        self.preset = preset
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.type = type
        self.tuningSnapshots = tuningSnapshots
    }
}
