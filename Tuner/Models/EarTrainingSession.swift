import Foundation
import SwiftData

@Model
final class EarTrainingSession {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var exerciseType: ExerciseType

    @Relationship(deleteRule: .cascade) var results: [ExerciseResult]

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        exerciseType: ExerciseType,
        results: [ExerciseResult] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.exerciseType = exerciseType
        self.results = results
    }
}
