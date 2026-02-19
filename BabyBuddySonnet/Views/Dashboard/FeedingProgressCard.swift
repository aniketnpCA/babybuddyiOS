import SwiftUI

struct FeedingProgressCard: View {
    let progress: Calculations.FeedingProgress?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.blue)
                Text("Feeding Progress")
                    .font(.headline)
                Spacer()
                if let progress {
                    statusBadge(progress.status)
                }
            }

            if let progress {
                VStack(spacing: 8) {
                    ProgressView(value: Double(progress.percentage), total: 100)
                        .tint(statusColor(progress.status))

                    HStack {
                        Text(String(format: "%.1f oz", progress.consumed))
                            .font(.title2.bold())
                        Text("/ \(String(format: "%.0f oz", progress.target))")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(progress.percentage)%")
                            .font(.headline)
                            .foregroundStyle(statusColor(progress.status))
                    }

                    HStack {
                        Text("Expected by now: \(String(format: "%.1f oz", progress.expectedByNow))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            } else {
                Text("No data")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statusBadge(_ status: Calculations.FeedingStatus) -> some View {
        Text(status.rawValue)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status).opacity(0.15))
            .foregroundStyle(statusColor(status))
            .clipShape(Capsule())
    }

    private func statusColor(_ status: Calculations.FeedingStatus) -> Color {
        switch status {
        case .complete: return .green
        case .onTrack: return .blue
        case .behind: return .orange
        case .critical: return .red
        }
    }
}
