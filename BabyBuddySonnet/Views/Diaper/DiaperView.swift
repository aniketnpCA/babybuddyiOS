import SwiftUI

struct DiaperView: View {
    let childID: Int
    @State private var viewModel = DiaperViewModel()
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
            .navigationTitle("Diaper")
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
                DiaperFormSheet(childID: childID) {
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
        } else if viewModel.todayChanges.isEmpty {
            EmptyStateView(icon: "circle.dotted", title: "No changes today", subtitle: "Tap + to log a diaper change")
        } else {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.todayChanges) { change in
                    DiaperRowView(change: change)
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
            let grouped = Calculations.groupByDate(viewModel.weekChanges) { $0.time }
            ForEach(grouped, id: \.key) { group in
                DisclosureGroup {
                    ForEach(group.items) { change in
                        DiaperRowView(change: change)
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
