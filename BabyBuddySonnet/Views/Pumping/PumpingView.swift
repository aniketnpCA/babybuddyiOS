import SwiftUI

struct PumpingView: View {
    let childID: Int
    @State private var viewModel = PumpingViewModel()
    @State private var showForm = false
    @State private var selectedTab = 0

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
                            Text(String(format: "%.1f", viewModel.todayTotalOz))
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
            .navigationTitle("Pumping")
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
                PumpingFormSheet(childID: childID) {
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
        } else if viewModel.todayPumping.isEmpty {
            EmptyStateView(icon: "drop.triangle", title: "No pumping today", subtitle: "Tap + to log a pumping session")
        } else {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.todayPumping) { session in
                    PumpingRowView(pumping: session)
                        .padding(.horizontal)
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
                            PumpingRowView(pumping: session)
                        }
                    } label: {
                        HStack {
                            Text(group.key)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            let total = Calculations.calculateTotalPumped(group.items)
                            Text(String(format: "%.1f oz", total))
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
