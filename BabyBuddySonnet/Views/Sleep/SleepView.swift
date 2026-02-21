import SwiftUI

struct SleepView: View {
    let childID: Int
    @State private var viewModel = SleepViewModel()
    @State private var showForm = false
    @State private var selectedTab = 0
    @State private var editingSleep: SleepRecord?
    @State private var customStart: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var customEnd: Date = Date()

    private let settings = SettingsService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let error = viewModel.error {
                        ErrorBannerView(message: error) {
                            viewModel.error = nil
                        }
                    }

                    // Timeline
                    SleepTimelineView(
                        periods: viewModel.timelinePeriods,
                        targetHours: settings.sleepTargetHours
                    )
                    .padding(.horizontal)

                    // Summary
                    HStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text(DateFormatting.formatMinutesToDuration(viewModel.todayTotalMinutes))
                                .font(.title.bold())
                                .foregroundStyle(.purple)
                            Text("total")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        VStack(spacing: 4) {
                            Text("\(viewModel.todayNaps.count)")
                                .font(.title.bold())
                            Text("naps")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        VStack(spacing: 4) {
                            Text("\(viewModel.todayNightSleep.count)")
                                .font(.title.bold())
                            Text("night")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    Picker("Period", selection: $selectedTab) {
                        Text("Today").tag(0)
                        Text("This Week").tag(1)
                        Text("Custom").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if selectedTab == 0 {
                        todayContent
                    } else if selectedTab == 1 {
                        weekContent
                    } else {
                        customContent
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Sleep")
            .overlay(alignment: .bottomTrailing) {
                FloatingActionButton(color: .purple) {
                    showForm = true
                }
            }
            .sheet(isPresented: $showForm) {
                SleepFormSheet(childID: childID) {
                    await reloadAll()
                }
            }
            .sheet(item: $editingSleep) { sleep in
                SleepFormSheet(childID: childID, editing: sleep) {
                    await reloadAll()
                }
            }
            .refreshable {
                await reloadAll()
            }
            .task {
                await viewModel.loadToday(childID: childID)
                await viewModel.loadWeek(childID: childID)
            }
        }
    }

    private func reloadAll() async {
        await viewModel.loadToday(childID: childID)
        await viewModel.loadWeek(childID: childID)
        if selectedTab == 2 {
            await viewModel.loadCustomRange(childID: childID, start: customStart, end: customEnd)
        }
        if let latestEnd = viewModel.todaySleep.first?.end,
           let date = DateFormatting.parseISO(latestEnd) {
            NotificationService.shared.rescheduleCategory(.sleep, lastEntryDate: date)
        }
    }

    @ViewBuilder
    private var todayContent: some View {
        if viewModel.isLoadingToday {
            LoadingView()
        } else if viewModel.todaySleep.isEmpty {
            EmptyStateView(icon: "moon", title: "No sleep recorded today", subtitle: "Tap + to log sleep")
        } else {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.todaySleep) { sleep in
                    Button { editingSleep = sleep } label: {
                        SleepRowView(sleep: sleep)
                            .padding(.horizontal)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading)
                }
            }
        }
    }

    @ViewBuilder
    private var weekContent: some View {
        if viewModel.isLoadingWeek {
            LoadingView()
        } else {
            let grouped = Calculations.groupByDate(viewModel.weekSleep) { $0.start }
            ForEach(grouped, id: \.key) { group in
                DisclosureGroup {
                    ForEach(group.items) { sleep in
                        Button { editingSleep = sleep } label: {
                            SleepRowView(sleep: sleep)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } label: {
                    HStack {
                        Text(group.key)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        let total = Calculations.calculateTotalSleepMinutes(group.items)
                        Text(DateFormatting.formatMinutesToDuration(total))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private var customContent: some View {
        VStack(spacing: 12) {
            HStack {
                DatePicker("From", selection: $customStart, displayedComponents: .date)
                    .labelsHidden()
                Text("to")
                    .foregroundStyle(.secondary)
                DatePicker("To", selection: $customEnd, displayedComponents: .date)
                    .labelsHidden()
                Button("Search") {
                    Task { await viewModel.loadCustomRange(childID: childID, start: customStart, end: customEnd) }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)

            if viewModel.isLoadingCustom {
                LoadingView()
            } else if viewModel.customSleep.isEmpty {
                EmptyStateView(icon: "magnifyingglass", title: "No results", subtitle: "Try a different date range")
            } else {
                let grouped = Calculations.groupByDate(viewModel.customSleep) { $0.start }
                ForEach(grouped, id: \.key) { group in
                    DisclosureGroup {
                        ForEach(group.items) { sleep in
                            Button { editingSleep = sleep } label: {
                                SleepRowView(sleep: sleep)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    } label: {
                        HStack {
                            Text(group.key)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            let total = Calculations.calculateTotalSleepMinutes(group.items)
                            Text(DateFormatting.formatMinutesToDuration(total))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}
