import SwiftUI

struct SleepView: View {
    let childID: Int
    @State private var viewModel = SleepViewModel()
    @State private var showForm = false
    @State private var selectedTab = 0

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
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if selectedTab == 0 {
                        todayContent
                    } else {
                        weekContent
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Sleep")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showForm = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showForm) {
                SleepFormSheet(childID: childID) {
                    await viewModel.loadToday(childID: childID)
                    await viewModel.loadWeek(childID: childID)
                }
            }
            .refreshable {
                await viewModel.loadToday(childID: childID)
                await viewModel.loadWeek(childID: childID)
            }
            .task {
                await viewModel.loadToday(childID: childID)
                await viewModel.loadWeek(childID: childID)
            }
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
                    SleepRowView(sleep: sleep)
                        .padding(.horizontal)
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
                        SleepRowView(sleep: sleep)
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
