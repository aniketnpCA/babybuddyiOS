import SwiftUI

struct ActiveTimersCard: View {
    let timers: [BabyTimer]
    var onStop: ((BabyTimer) -> Void)?
    var onDelete: ((BabyTimer) -> Void)?
    var onStart: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Timers", systemImage: "timer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
                Spacer()
                if let onStart {
                    Button {
                        onStart()
                    } label: {
                        Label("Start", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.orange)
                    }
                }
            }

            if timers.isEmpty {
                Text("No active timers")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            } else {
                ForEach(timers) { timer in
                    HStack(spacing: 10) {
                        Image(systemName: iconForTimer(timer.name ?? ""))
                            .font(.body)
                            .foregroundStyle(colorForTimer(timer.name ?? ""))
                            .frame(width: 24)

                        Text(timer.name.map { $0.isEmpty ? "Timer" : $0 } ?? "Timer")
                            .font(.subheadline.weight(.medium))

                        Spacer()

                        if let startDate = DateFormatting.parseISO(timer.start) {
                            Text(startDate, style: .timer)
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        if let onStop {
                            Button {
                                onStop(timer)
                            } label: {
                                Image(systemName: "stop.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.red)
                            }
                        }

                        if let onDelete {
                            Button {
                                onDelete(timer)
                            } label: {
                                Image(systemName: "trash.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func iconForTimer(_ name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("feed") || lower.contains("bottle") || lower.contains("breast") {
            return "drop.fill"
        } else if lower.contains("sleep") || lower.contains("nap") {
            return "moon.fill"
        } else if lower.contains("pump") {
            return "drop.triangle.fill"
        } else if lower.contains("tummy") || lower.contains("play") {
            return "figure.play"
        }
        return "timer"
    }

    private func colorForTimer(_ name: String) -> Color {
        let lower = name.lowercased()
        if lower.contains("feed") || lower.contains("bottle") || lower.contains("breast") {
            return .blue
        } else if lower.contains("sleep") || lower.contains("nap") {
            return .purple
        } else if lower.contains("pump") {
            return .orange
        } else if lower.contains("tummy") || lower.contains("play") {
            return .green
        }
        return .orange
    }
}
