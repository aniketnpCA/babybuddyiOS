import SwiftUI

struct NoteRowView: View {
    let note: Note

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.body)
                .foregroundStyle(.yellow)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(note.note)
                    .font(.subheadline)
                    .lineLimit(2)

                Text(DateFormatting.formatTime(note.time))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }
}
