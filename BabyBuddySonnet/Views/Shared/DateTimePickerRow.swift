import SwiftUI

struct DateTimePickerRow: View {
    let label: String
    @Binding var date: Date

    var body: some View {
        DatePicker(label, selection: $date)
            .datePickerStyle(.compact)
    }
}
