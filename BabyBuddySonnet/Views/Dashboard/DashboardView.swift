import SwiftUI

struct DashboardView: View {
    let child: Child
    @State private var viewModel = DashboardViewModel()
    @State private var showFeedingForm = false
    @State private var showPumpingForm = false
    @State private var showSleepForm = false
    @State private var showDiaperForm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let error = viewModel.error {
                        ErrorBannerView(message: error) {
                            viewModel.error = nil
                        }
                    }

                    ChildProfileCard(child: child)
                        .padding(.horizontal)

                    QuickActionsGrid(
                        showFeedingForm: $showFeedingForm,
                        showPumpingForm: $showPumpingForm,
                        showSleepForm: $showSleepForm,
                        showDiaperForm: $showDiaperForm
                    )
                    .padding(.horizontal)

                    FeedingProgressCard(chartData: viewModel.cumulativeChartData)
                        .padding(.horizontal)

                    DailySurplusCard(
                        pumpedOz: viewModel.todayPumpedOz,
                        consumedOz: viewModel.todayConsumedOz
                    )
                    .padding(.horizontal)

                    // Last activity
                    if let lastFeeding = viewModel.lastFeedingTime {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(.secondary)
                            Text("Last feeding: \(DateFormatting.formatTime(lastFeeding))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    // Sleep summary
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundStyle(.purple)
                        Text("Sleep today: \(DateFormatting.formatMinutesToDuration(viewModel.todaySleepMinutes))")
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .refreshable {
                await viewModel.loadDashboard(childID: child.id)
            }
            .task {
                await viewModel.loadDashboard(childID: child.id)
            }
            .sheet(isPresented: $showFeedingForm) {
                FeedingFormSheet(childID: child.id) {
                    await viewModel.loadDashboard(childID: child.id)
                }
            }
            .sheet(isPresented: $showPumpingForm) {
                PumpingFormSheet(childID: child.id) {
                    await viewModel.loadDashboard(childID: child.id)
                }
            }
            .sheet(isPresented: $showSleepForm) {
                SleepFormSheet(childID: child.id) {
                    await viewModel.loadDashboard(childID: child.id)
                }
            }
            .sheet(isPresented: $showDiaperForm) {
                DiaperFormSheet(childID: child.id) {
                    await viewModel.loadDashboard(childID: child.id)
                }
            }
        }
    }
}
