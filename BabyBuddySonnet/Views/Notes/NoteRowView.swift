import SwiftUI

struct NoteRowView: View {
    let note: Note

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "note.text")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Color.jayNotesFallback, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(DateFormatting.formatTime(note.time))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text(note.note)
                    .font(.subheadline)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
    }
}
