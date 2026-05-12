import Foundation
import SwiftData

@Model
final class ExerciseResult {
    var playedNote: String
    var playedInterval: Interval?
    var userAnswer: String
    var correct: Bool
    var responseTimeSeconds: Double
    var answeredAt: Date

    init(
        playedNote: String,
        playedInterval: Interval? = nil,
        userAnswer: String,
        correct: Bool,
        responseTimeSeconds: Double,
        answeredAt: Date = Date()
    ) {
        self.playedNote = playedNote
        self.playedInterval = playedInterval
        self.userAnswer = userAnswer
        self.correct = correct
        self.responseTimeSeconds = responseTimeSeconds
        self.answeredAt = answeredAt
    }
}
