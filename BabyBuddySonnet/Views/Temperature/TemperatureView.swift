import SwiftUI

struct TemperatureView: View {
    let childID: Int
    @State private var viewModel = TemperatureViewModel()
    @State private var showForm = false
    @State private var selectedTab = 0
    @State private var editingTemperature: Temperature?
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
                    if let latest = viewModel.todayTemperatures.first {
                        HStack(spacing: 24) {
                            VStack(spacing: 4) {
                                Text(String(format: "%.1f\u{00B0}", latest.temperature))
                                    .font(.title.bold())
                                    .foregroundStyle(temperatureColor(latest.temperature))
                                Text("latest")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            VStack(spacing: 4) {
                                Text("\(viewModel.todayTemperatures.count)")
                                    .font(.title.bold())
                                Text("readings")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }

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
            .navigationTitle("Temperature")
            .overlay(alignment: .bottomTrailing) {
                FloatingActionButton(color: .jayTemperatureFallback) {
                    showForm = true
                }
            }
            .sheet(isPresented: $showForm) {
                TemperatureFormSheet(childID: childID) {
                    await reloadAll()
                }
            }
            .sheet(item: $editingTemperature) { temp in
                TemperatureFormSheet(childID: childID, editing: temp) {
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

    private func temperatureColor(_ temp: Double) -> Color {
        if temp >= 100.4 { return .red }
        if temp >= 99.5 { return .orange }
        return .green
    }

    @ViewBuilder
    private var todayContent: some View {
        if viewModel.isLoadingToday {
            LoadingView()
        } else if viewModel.todayTemperatures.isEmpty {
            EmptyStateView(icon: "thermometer.medium", title: "No readings today", subtitle: "Tap + to log a temperature")
        } else {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.todayTemperatures) { temp in
                    Button { editingTemperature = temp } label: {
                        TemperatureRowView(temperature: temp)
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
            let grouped = Calculations.groupByDate(viewModel.weekTemperatures) { $0.time }
            ForEach(grouped, id: \.key) { group in
                DisclosureGroup {
                    ForEach(group.items) { temp in
                        Button { editingTemperature = temp } label: {
                            TemperatureRowView(temperature: temp)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } label: {
                    HStack {
                        Text(group.key)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(group.items.count) readings")
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
            } else if viewModel.customTemperatures.isEmpty {
                EmptyStateView(icon: "magnifyingglass", title: "No results", subtitle: "Try a different date range")
            } else {
                let grouped = Calculations.groupByDate(viewModel.customTemperatures) { $0.time }
                ForEach(grouped, id: \.key) { group in
                    DisclosureGroup {
                        ForEach(group.items) { temp in
                            Button { editingTemperature = temp } label: {
                                TemperatureRowView(temperature: temp)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    } label: {
                        HStack {
                            Text(group.key)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(group.items.count) readings")
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
