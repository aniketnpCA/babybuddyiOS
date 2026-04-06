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

// MARK: - Timeline Entry Row

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
                VStack(spacing: 2) {
                    Text(DateFormatting.formatTimeFromDate(entry.time))
                        .font(.caption.weight(.medium).monospacedDigit())
                        .foregroundStyle(.secondary)
                    if let end = entry.endTime {
                        Text(DateFormatting.formatTimeFromDate(end))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(width: 58, alignment: .trailing)

                // Timeline rail with icon
                VStack(spacing: 0) {
                    // Line above icon
                    if !isFirst {
                        Rectangle()
                            .fill(entry.color.opacity(0.3))
                            .frame(width: 2, height: 8)
                    } else {
                        Spacer().frame(width: 2, height: 8)
                    }

                    // Icon bubble
                    ZStack {
                        Circle()
                            .fill(entry.color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: entry.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(entry.color)
                    }

                    // Duration bar (for activities with duration)
                    if let mins = entry.durationMinutes, mins > 0 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(entry.color.opacity(0.25))
                            .frame(width: 6, height: durationBarHeight(minutes: mins))
                    }

                    // Line below icon
                    if !isLast || intervalFromPrevious != nil {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.15))
                            .frame(width: 2, height: 8)
                    } else {
                        Spacer().frame(width: 2, height: 8)
                    }
                }
                .frame(width: 48)

                // Content card
                VStack(alignment: .leading, spacing: 4) {
                    if let mins = entry.durationMinutes {
                        Text("\(DateFormatting.formatTimeFromDate(entry.time)) \u{2013} \(DateFormatting.formatTimeFromDate(entry.endTime!)) (\(DateFormatting.formatMinutesToDuration(mins)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(entry.title)
                        .font(.subheadline.weight(.semibold))

                    if !entry.subtitle.isEmpty {
                        Text(entry.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                )
                .padding(.leading, 4)
            }

            // Interval indicator between this entry and the next
            if let interval = intervalFromPrevious {
                HStack(spacing: 0) {
                    Spacer().frame(width: 58)

                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.15))
                            .frame(width: 2, height: 12)

                        Text(interval)
                            .font(.caption2.weight(.medium).monospacedDigit())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.secondary.opacity(0.08))
                            )

                        Rectangle()
                            .fill(Color.secondary.opacity(0.15))
                            .frame(width: 2, height: 12)
                    }
                    .frame(width: 48)

                    Spacer()
                }
            }
        }
    }

    private func durationBarHeight(minutes: Int) -> CGFloat {
        // Scale: 5 minutes = 8pt, max at 60pt for 60+ minutes
        let scaled = CGFloat(minutes) * 1.0
        return min(max(scaled, 4), 60)
    }
}
