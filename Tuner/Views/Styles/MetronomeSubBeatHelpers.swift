import SwiftUI

func subBeatColor(
    beat: Int,
    subBeat: Int,
    currentBeat: Int,
    currentSubBeat: Int,
    isPlaying: Bool
) -> Color {
    guard isPlaying, beat == currentBeat, subBeat == currentSubBeat else {
        return Color(.systemGray5)
    }
    return Color.green.opacity(0.5)
}
