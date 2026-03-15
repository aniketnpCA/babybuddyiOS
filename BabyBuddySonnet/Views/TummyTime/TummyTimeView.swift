import SwiftUI

struct TummyTimeView: View {
    let childID: Int
    @State private var viewModel = TummyTimeViewModel()
    @State private var showForm = false
    @State private var selectedTab = 0
    @State private var editingTummyTime: TummyTime?
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

                    // Summary
                    HStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text(DateFormatting.formatMinutesToDuration(viewModel.todayTotalMinutes))
                                .font(.title.bold())
                                .foregroundStyle(.green)
                            Text("today")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        VStack(spacing: 4) {
                            Text("\(viewModel.todayTummyTimes.count)")
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
            .navigationTitle("Tummy Time")
            .overlay(alignment: .bottomTrailing) {
                FloatingActionButton(color: .green) {
                    showForm = true
                }
            }
            .sheet(isPresented: $showForm) {
                TummyTimeFormSheet(childID: childID) {
                    await reloadAll()
                }
            }
            .sheet(item: $editingTummyTime) { tt in
                TummyTimeFormSheet(childID: childID, editing: tt) {
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
    }

    @ViewBuilder
    private var todayContent: some View {
        if viewModel.isLoadingToday {
            LoadingView()
        } else if viewModel.todayTummyTimes.isEmpty {
            EmptyStateView(icon: "figure.play", title: "No tummy time today", subtitle: "Tap + to log a session")
        } else {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.todayTummyTimes) { tt in
                    Button { editingTummyTime = tt } label: {
                        TummyTimeRowView(tummyTime: tt)
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
            let grouped = Calculations.groupByDate(viewModel.weekTummyTimes) { $0.start }
            ForEach(grouped, id: \.key) { group in
                DisclosureGroup {
                    ForEach(group.items) { tt in
                        Button { editingTummyTime = tt } label: {
                            TummyTimeRowView(tummyTime: tt)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } label: {
                    HStack {
                        Text(group.key)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(group.items.count) sessions")
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
            } else if viewModel.customTummyTimes.isEmpty {
                EmptyStateView(icon: "magnifyingglass", title: "No results", subtitle: "Try a different date range")
            } else {
                let grouped = Calculations.groupByDate(viewModel.customTummyTimes) { $0.start }
                ForEach(grouped, id: \.key) { group in
                    DisclosureGroup {
                        ForEach(group.items) { tt in
                            Button { editingTummyTime = tt } label: {
                                TummyTimeRowView(tummyTime: tt)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    } label: {
                        HStack {
                            Text(group.key)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(group.items.count) sessions")
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
