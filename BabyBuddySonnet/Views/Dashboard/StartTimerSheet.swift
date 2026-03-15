import SwiftUI

struct StartTimerSheet: View {
    let childID: Int
    let onStart: (String?) async -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var timerName = ""
    @State private var isStarting = false

    private let presets = ["Feeding", "Sleep", "Tummy Time", "Pumping"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Timer Name") {
                    TextField("Optional name", text: $timerName)
                        .autocorrectionDisabled()
                }

                Section("Quick Start") {
                    ForEach(presets, id: \.self) { preset in
                        Button {
                            timerName = preset
                            Task { await start() }
                        } label: {
                            Label(preset, systemImage: iconFor(preset))
                        }
                    }
                }
            }
            .navigationTitle("Start Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await start() }
                    } label: {
                        if isStarting {
                            ProgressView()
                        } else {
                            Text("Start")
                        }
                    }
                    .disabled(isStarting)
                }
            }
        }
    }

    private func start() async {
        isStarting = true
        defer { isStarting = false }
        await onStart(timerName.isEmpty ? nil : timerName)
        dismiss()
    }

    private func iconFor(_ name: String) -> String {
        switch name {
        case "Feeding": return "drop.fill"
        case "Sleep": return "moon.fill"
        case "Tummy Time": return "figure.play"
        case "Pumping": return "drop.triangle.fill"
        default: return "timer"
        }
    }
}
