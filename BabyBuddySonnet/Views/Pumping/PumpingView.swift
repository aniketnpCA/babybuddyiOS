import SwiftUI

struct PumpingView: View {
    let childID: Int
    @State private var viewModel = PumpingViewModel()
    @State private var showForm = false
    @State private var selectedTab = 0
    @State private var editingPumping: Pumping?
    @State private var customStart: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var customEnd: Date = Date()

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
                                .foregroundStyle(.orange)
                            Text("oz today")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        VStack(spacing: 4) {
                            Text("\(viewModel.todayPumping.count)")
                                .font(.title.bold())
                            Text("sessions")
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
            .navigationTitle("Pumping")
            .overlay(alignment: .bottomTrailing) {
                FloatingActionButton(color: .orange) {
                    showForm = true
                }
            }
            .sheet(isPresented: $showForm) {
                PumpingFormSheet(childID: childID) {
                    await reloadAll()
                }
            }
            .sheet(item: $editingPumping) { pumping in
                PumpingFormSheet(childID: childID, editing: pumping) {
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
        if let latestEnd = viewModel.todayPumping.first?.end,
           let date = DateFormatting.parseISO(latestEnd) {
            NotificationService.shared.rescheduleCategory(.pumping, lastEntryDate: date)
        }
    }

    @ViewBuilder
    private var todayContent: some View {
        if viewModel.isLoadingToday {
            LoadingView()
        } else if viewModel.todayPumping.isEmpty {
            EmptyStateView(icon: "drop.triangle", title: "No pumping today", subtitle: "Tap + to log a pumping session")
        } else {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.todayPumping) { session in
                    Button { editingPumping = session } label: {
                        PumpingRowView(pumping: session)
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
            PumpingWeekChart(data: viewModel.weeklyChartData)
                .padding(.horizontal)

            if viewModel.isLoadingWeek {
                LoadingView()
            } else {
                let grouped = Calculations.groupByDate(viewModel.weekPumping) { $0.start }
                ForEach(grouped, id: \.key) { group in
                    DisclosureGroup {
                        ForEach(group.items) { session in
                            Button { editingPumping = session } label: {
                                PumpingRowView(pumping: session)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    } label: {
                        HStack {
                            Text(group.key)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            let total = Calculations.calculateTotalPumped(group.items)
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
            } else if viewModel.customPumping.isEmpty {
                EmptyStateView(icon: "magnifyingglass", title: "No results", subtitle: "Try a different date range")
            } else {
                let grouped = Calculations.groupByDate(viewModel.customPumping) { $0.start }
                ForEach(grouped, id: \.key) { group in
                    DisclosureGroup {
                        ForEach(group.items) { session in
                            Button { editingPumping = session } label: {
                                PumpingRowView(pumping: session)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    } label: {
                        HStack {
                            Text(group.key)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            let total = Calculations.calculateTotalPumped(group.items)
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
