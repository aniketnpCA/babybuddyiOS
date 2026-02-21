import SwiftUI

struct DiaperView: View {
    let childID: Int
    @State private var viewModel = DiaperViewModel()
    @State private var showForm = false
    @State private var selectedTab = 0
    @State private var editingChange: DiaperChange?
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
                            Text("\(viewModel.todayTotalCount)")
                                .font(.title.bold())
                                .foregroundStyle(.teal)
                            Text("total")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        VStack(spacing: 4) {
                            Text("\(viewModel.todayWetCount)")
                                .font(.title.bold())
                            Text("wet")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        VStack(spacing: 4) {
                            Text("\(viewModel.todaySolidCount)")
                                .font(.title.bold())
                            Text("solid")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        VStack(spacing: 4) {
                            Text("\(viewModel.todayBothCount)")
                                .font(.title.bold())
                            Text("both")
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
            .navigationTitle("Diaper")
            .overlay(alignment: .bottomTrailing) {
                FloatingActionButton(color: .teal) {
                    showForm = true
                }
            }
            .sheet(isPresented: $showForm) {
                DiaperFormSheet(childID: childID) {
                    await reloadAll()
                }
            }
            .sheet(item: $editingChange) { change in
                DiaperFormSheet(childID: childID, editing: change) {
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
        if let latestTime = viewModel.todayChanges.first?.time,
           let date = DateFormatting.parseISO(latestTime) {
            NotificationService.shared.rescheduleCategory(.diaper, lastEntryDate: date)
        }
    }

    @ViewBuilder
    private var todayContent: some View {
        if viewModel.isLoadingToday {
            LoadingView()
        } else if viewModel.todayChanges.isEmpty {
            EmptyStateView(icon: "circle.dotted", title: "No changes today", subtitle: "Tap + to log a diaper change")
        } else {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.todayChanges) { change in
                    Button { editingChange = change } label: {
                        DiaperRowView(change: change)
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
            let grouped = Calculations.groupByDate(viewModel.weekChanges) { $0.time }
            ForEach(grouped, id: \.key) { group in
                DisclosureGroup {
                    ForEach(group.items) { change in
                        Button { editingChange = change } label: {
                            DiaperRowView(change: change)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } label: {
                    HStack {
                        Text(group.key)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(group.items.count) changes")
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
            } else if viewModel.customChanges.isEmpty {
                EmptyStateView(icon: "magnifyingglass", title: "No results", subtitle: "Try a different date range")
            } else {
                let grouped = Calculations.groupByDate(viewModel.customChanges) { $0.time }
                ForEach(grouped, id: \.key) { group in
                    DisclosureGroup {
                        ForEach(group.items) { change in
                            Button { editingChange = change } label: {
                                DiaperRowView(change: change)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    } label: {
                        HStack {
                            Text(group.key)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(group.items.count) changes")
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
