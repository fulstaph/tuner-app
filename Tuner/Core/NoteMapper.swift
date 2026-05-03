import Foundation

enum NoteMapper {
    static let noteNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]

    static func map(
        frequency: Double,
        referencePitch: Double = 440.0,
        transposition: Int = 0
    ) -> TunerData {
        guard frequency > 0 else {
            return TunerData()
        }

        let midiNote = 12.0 * log2(frequency / referencePitch) + 69.0
        let roundedMidi = Int(round(midiNote))
        let cents = (midiNote - Double(roundedMidi)) * 100.0

        let transposed = roundedMidi + transposition
        let noteIndex = ((transposed % 12) + 12) % 12
        let octave = transposed / 12 - 1

        return TunerData(
            frequency: frequency,
            note: noteNames[noteIndex],
            octave: octave,
            cents: cents,
            isActive: true
        )
    }
}
