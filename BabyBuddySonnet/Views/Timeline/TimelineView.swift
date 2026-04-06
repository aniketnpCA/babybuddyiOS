import SwiftUI

struct TimelineTabView: View {
    let childID: Int
    @State private var viewModel = TimelineViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Date header with navigation
                    dateHeader
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 16)

                    if let error = viewModel.error {
                        ErrorBannerView(message: error) {
                            viewModel.error = nil
                        }
                        .padding(.horizontal)
                    }

                    if viewModel.isLoading {
                        LoadingView()
                            .padding(.top, 40)
                    } else if viewModel.entries.isEmpty {
                        EmptyStateView(
                            icon: "clock",
                            title: "No activities",
                            subtitle: "Nothing recorded for this day"
                        )
                        .padding(.top, 40)
                    } else {
                        timelineContent
                    }

                    Spacer().frame(height: 80)
                }
                .padding(.vertical)
            }
            .navigationTitle("Timeline")
            .refreshable {
                await viewModel.loadTimeline(childID: childID)
            }
            .task {
                await viewModel.loadTimeline(childID: childID)
            }
            .onChange(of: viewModel.selectedDate) {
                Task {
                    await viewModel.loadTimeline(childID: childID)
                }
            }
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    viewModel.goToPreviousDay()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.primary)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(viewModel.selectedDate.formatted(.dateTime.weekday(.wide)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(viewModel.selectedDate.formatted(.dateTime.month(.wide).day()))
                        .font(.title2.weight(.bold))
                }

                Spacer()

                Button {
                    viewModel.goToNextDay()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(viewModel.isToday ? .tertiary : .primary)
                }
                .disabled(viewModel.isToday)
            }

            if !viewModel.isToday {
                Button("Today") {
                    viewModel.goToToday()
                }
                .font(.caption.weight(.medium))
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    // MARK: - Timeline Content

    private var timelineContent: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                TimelineEntryRow(
                    entry: entry,
                    isFirst: index == 0,
                    isLast: index == viewModel.entries.count - 1,
                    intervalFromPrevious: intervalText(at: index)
                )
            }
        }
        .padding(.horizontal)
    }

    private func intervalText(at index: Int) -> String? {
        guard index < viewModel.entries.count - 1 else { return nil }
        let current = viewModel.entries[index]
        let next = viewModel.entries[index + 1]
        // "next" is older since entries are sorted newest-first
        let olderTime = next.endTime ?? next.time
        let newerTime = current.time
        let interval = newerTime.timeIntervalSince(olderTime)
        guard interval > 60 else { return nil } // skip <1 min gaps
        return DateFormatting.formatMinutesToDuration(Int(interval / 60))
    }
}

// MARK: - Timeline Entry Row (Structured-style)

struct TimelineEntryRow: View {
    let entry: TimelineEntry
    let isFirst: Bool
    let isLast: Bool
    let intervalFromPrevious: String?

    var body: some View {
        VStack(spacing: 0) {
            // Main entry
            HStack(alignment: .top, spacing: 0) {
                // Time column
                Text(DateFormatting.formatTimeFromDate(entry.time))
                    .font(.caption.weight(.medium).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 54, alignment: .trailing)

                // Timeline rail: icon circle + duration pill
                VStack(spacing: 0) {
                    // Connector above
                    if !isFirst {
                        Capsule()
                            .fill(Color.secondary.opacity(0.12))
                            .frame(width: 3, height: 6)
                    } else {
                        Spacer().frame(height: 6)
                    }

                    // Icon circle (large, filled, white icon)
                    ZStack {
                        Circle()
                            .fill(entry.color)
                            .frame(width: 44, height: 44)
                        Image(systemName: entry.icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    // Duration pill (Structured-style capsule below icon)
                    if let mins = entry.durationMinutes, mins > 0 {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(entry.color.opacity(0.5))
                            .frame(width: 24, height: durationPillHeight(minutes: mins))
                    }

                    // Connector below
                    if !isLast || intervalFromPrevious != nil {
                        Capsule()
                            .fill(Color.secondary.opacity(0.12))
                            .frame(width: 3, height: 6)
                    } else {
                        Spacer().frame(height: 6)
                    }
                }
                .frame(width: 52)

                // Content card
                VStack(alignment: .leading, spacing: 4) {
                    if let mins = entry.durationMinutes {
                        Text("\(DateFormatting.formatTimeFromDate(entry.time)) \u{2013} \(DateFormatting.formatTimeFromDate(entry.endTime!)) (\(DateFormatting.formatMinutesToDuration(mins)))")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    Text(entry.title)
                        .font(.subheadline.weight(.bold))

                    if !entry.subtitle.isEmpty {
                        Text(entry.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(entry.color.opacity(0.06))
                )
                .padding(.leading, 6)
            }

            // Interval indicator between this entry and the next
            if let interval = intervalFromPrevious {
                HStack(spacing: 0) {
                    Spacer().frame(width: 54)

                    VStack(spacing: 0) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.12))
                            .frame(width: 3, height: 10)

                        Text(interval)
                            .font(.caption2.weight(.medium).monospacedDigit())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.secondary.opacity(0.06))
                            )

                        Capsule()
                            .fill(Color.secondary.opacity(0.12))
                            .frame(width: 3, height: 10)
                    }
                    .frame(width: 52)

                    Spacer()
                }
            }
        }
    }

    private func durationPillHeight(minutes: Int) -> CGFloat {
        // Structured-style: scale duration visually
        // 5 min = 10pt, 15 min = 20pt, 30 min = 35pt, 60+ min = 55pt
        let scaled = 6.0 + CGFloat(minutes) * 0.8
        return min(max(scaled, 8), 55)
    }
}
