import SwiftUI

nonisolated enum TimerActivityType: String, CaseIterable, Identifiable, Sendable {
    case feeding = "Feeding"
    case sleep = "Sleep"
    case pumping = "Pumping"
    case tummyTime = "Tummy Time"
    case none = "Just Stop"

    nonisolated var id: String { rawValue }

    var icon: String {
        switch self {
        case .feeding: "drop.fill"
        case .sleep: "moon.fill"
        case .pumping: "drop.triangle.fill"
        case .tummyTime: "figure.play"
        case .none: "stop.fill"
        }
    }

    var color: Color {
        switch self {
        case .feeding: .blue
        case .sleep: .purple
        case .pumping: .orange
        case .tummyTime: .green
        case .none: .secondary
        }
    }
}

struct StopTimerSheet: View {
    let timer: BabyTimer
    let childID: Int
    let onStop: () async -> BabyTimer?
    let onLogActivity: (TimerActivityType, Date, Date) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var isStopping = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Timer info
                VStack(spacing: 8) {
                    Text(timer.name.map { $0.isEmpty ? "Timer" : $0 } ?? "Timer")
                        .font(.title2.weight(.semibold))

                    if let startDate = DateFormatting.parseISO(timer.start) {
                        Text(startDate, style: .timer)
                            .font(.system(.largeTitle, design: .monospaced, weight: .medium))
                            .foregroundStyle(.orange)

                        Text("Started \(startDate.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top)

                Divider()

                // Activity type selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Log as activity")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    ForEach(TimerActivityType.allCases) { activityType in
                        Button {
                            Task { await stopAndLog(activityType) }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: activityType.icon)
                                    .font(.body)
                                    .foregroundStyle(activityType.color)
                                    .frame(width: 28)

                                Text(activityType.rawValue)
                                    .font(.body)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if activityType != .none {
                            Divider()
                        }
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                if isStopping {
                    ProgressView("Stopping timer...")
                }

                Spacer()
            }
            .navigationTitle("Stop Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func stopAndLog(_ activityType: TimerActivityType) async {
        guard !isStopping else { return }
        isStopping = true
        defer { isStopping = false }

        let startDate = DateFormatting.parseISO(timer.start) ?? Date().addingTimeInterval(-3600)
        let endDate = Date()

        _ = await onStop()
        dismiss()

        if activityType != .none {
            onLogActivity(activityType, startDate, endDate)
        }
    }
}
