import SwiftUI

struct FeedingView: View {
    let childID: Int
    @State private var viewModel = FeedingViewModel()
    @State private var showForm = false
    @State private var selectedTab = 0
    @State private var editingFeeding: Feeding?
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

                    // Summary card
                    HStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text(String(format: "%.2f", viewModel.todayTotalOz))
                                .font(.title.bold())
                                .foregroundStyle(.blue)
                            Text("oz today")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        VStack(spacing: 4) {
                            Text("\(viewModel.todayBottleCount)")
                                .font(.title.bold())
                            Text("bottles")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        VStack(spacing: 4) {
                            Text("\(viewModel.todayBreastCount)")
                                .font(.title.bold())
                            Text("breast")
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
            .navigationTitle("Feeding")
            .overlay(alignment: .bottomTrailing) {
                FloatingActionButton(color: .blue) {
                    showForm = true
                }
            }
            .sheet(isPresented: $showForm) {
                FeedingFormSheet(childID: childID) {
                    await reloadAll()
                }
            }
            .sheet(item: $editingFeeding) { feeding in
                FeedingFormSheet(childID: childID, editing: feeding) {
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
        if let latestEnd = viewModel.todayFeedings.first?.end,
           let date = DateFormatting.parseISO(latestEnd) {
            NotificationService.shared.rescheduleCategory(.feeding, lastEntryDate: date)
        }
    }

    @ViewBuilder
    private var todayContent: some View {
        FeedingCumulativeChart(data: viewModel.cumulativeChartData)
            .padding(.horizontal)

        if viewModel.isLoadingToday {
            LoadingView()
        } else if viewModel.todayFeedings.isEmpty {
            EmptyStateView(icon: "drop", title: "No feedings today", subtitle: "Tap + to log a feeding")
        } else {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.todayFeedings) { feeding in
                    Button { editingFeeding = feeding } label: {
                        FeedingRowView(feeding: feeding)
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
        VStack(spacing: 16) {
            if viewModel.isLoadingWeek {
                LoadingView()
            } else {
                FeedingWeeklyBarChart(
                    data: viewModel.weeklyChartData,
                    targetAmount: settings.feedingTargetAmount
                )
                .padding(.horizontal)

                let grouped = Calculations.groupByDate(viewModel.weekFeedings) { $0.start }
                ForEach(grouped, id: \.key) { group in
                    DisclosureGroup {
                        ForEach(group.items) { feeding in
                            Button { editingFeeding = feeding } label: {
                                FeedingRowView(feeding: feeding)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    } label: {
                        HStack {
                            Text(group.key)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            let total = Calculations.calculateTotalConsumed(group.items)
                            Text(String(format: "%.2f oz", total))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
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
            } else if viewModel.customFeedings.isEmpty {
                EmptyStateView(icon: "magnifyingglass", title: "No results", subtitle: "Try a different date range")
            } else {
                FeedingWeeklyBarChart(
                    data: viewModel.customChartData,
                    targetAmount: settings.feedingTargetAmount
                )
                .padding(.horizontal)

                let grouped = Calculations.groupByDate(viewModel.customFeedings) { $0.start }
                ForEach(grouped, id: \.key) { group in
                    DisclosureGroup {
                        ForEach(group.items) { feeding in
                            Button { editingFeeding = feeding } label: {
                                FeedingRowView(feeding: feeding)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    } label: {
                        HStack {
                            Text(group.key)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            let total = Calculations.calculateTotalConsumed(group.items)
                            Text(String(format: "%.2f oz", total))
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
