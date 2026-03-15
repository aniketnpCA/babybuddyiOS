import SwiftUI

struct DashboardView: View {
    let child: Child
    private let settings = SettingsService.shared
    private var theme: PetModeTheme { settings.theme }
    @State private var viewModel = DashboardViewModel()
    @State private var showFeedingForm = false
    @State private var showPumpingForm = false
    @State private var showSleepForm = false
    @State private var showDiaperForm = false
    @State private var showCustomize = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                        if let error = viewModel.error {
                            ErrorBannerView(message: error) {
                                viewModel.error = nil
                            }
                        }

                        ChildProfileCard(
                            child: child,
                            latestWeight: viewModel.latestWeight,
                            latestHeight: viewModel.latestHeight,
                            latestHeadCircumference: viewModel.latestHeadCircumference
                        )
                        .padding(.horizontal)

                        if !viewModel.activeTimers.isEmpty {
                            ActiveTimersCard(timers: viewModel.activeTimers)
                                .padding(.horizontal)
                        }

                        NextExpectedCard(
                            nextFeedingTime: viewModel.nextFeedingTime,
                            nextPumpingTime: viewModel.nextPumpingTime,
                            nextDiaperTime: viewModel.nextDiaperTime
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
                                Text("\(theme.dashboardLastFeedingLabel) \(DateFormatting.formatTime(lastFeeding))")
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
                            Text("\(theme.dashboardSleepTodayLabel) \(DateFormatting.formatMinutesToDuration(viewModel.todaySleepMinutes))")
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)

                        // Extra dashboard widgets
                        ForEach(settings.dashboardWidgets) { widget in
                            dashboardWidgetView(for: widget)
                                .padding(.horizontal)
                        }

                        // Customize button
                        Button {
                            showCustomize = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.subheadline)
                                Text("Customize Dashboard")
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)

                        // Bottom spacer so content doesn't hide behind FAB
                        Spacer().frame(height: 60)
                    }
                    .padding(.vertical)
            }
            .overlay(alignment: .bottomTrailing) {
                ExpandableFloatingActionButton(items: fabItems)
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
                await viewModel.loadDashboard(childID: child.id, childName: child.displayName, birthDate: child.birthDate)
                await NotificationService.shared.rescheduleAll(childID: child.id)
            }
            .task {
                await viewModel.loadDashboard(childID: child.id, childName: child.displayName, birthDate: child.birthDate)
                await NotificationService.shared.rescheduleAll(childID: child.id)
            }
            .sheet(isPresented: $showFeedingForm) {
                FeedingFormSheet(childID: child.id) {
                    await viewModel.loadDashboard(childID: child.id, childName: child.displayName, birthDate: child.birthDate)
                    await NotificationService.shared.rescheduleAll(childID: child.id)
                }
            }
            .sheet(isPresented: $showPumpingForm) {
                PumpingFormSheet(childID: child.id) {
                    await viewModel.loadDashboard(childID: child.id, childName: child.displayName, birthDate: child.birthDate)
                    await NotificationService.shared.rescheduleAll(childID: child.id)
                }
            }
            .sheet(isPresented: $showSleepForm) {
                SleepFormSheet(childID: child.id) {
                    await viewModel.loadDashboard(childID: child.id, childName: child.displayName, birthDate: child.birthDate)
                    await NotificationService.shared.rescheduleAll(childID: child.id)
                }
            }
            .sheet(isPresented: $showDiaperForm) {
                DiaperFormSheet(childID: child.id) {
                    await viewModel.loadDashboard(childID: child.id, childName: child.displayName, birthDate: child.birthDate)
                    await NotificationService.shared.rescheduleAll(childID: child.id)
                }
            }
            .sheet(isPresented: $showCustomize) {
                DashboardCustomizeSheet()
            }
        }
    }

    @ViewBuilder
    private func dashboardWidgetView(for widget: DashboardWidget) -> some View {
        switch widget {
        case .feedingWeeklyChart:
            FeedingWeeklyBarChart(
                data: viewModel.weeklyFeedingChartData,
                targetAmount: settings.feedingTargetAmount
            )

        case .pumpingWeeklyChart:
            PumpingWeekChart(data: viewModel.weeklyPumpingChartData)

        case .growthChart:
            GrowthChart(
                weightMeasurements: viewModel.weightMeasurements,
                heightMeasurements: viewModel.heightMeasurements,
                headCircumferenceMeasurements: viewModel.headCircumferenceMeasurements,
                birthDate: child.birthDate
            )

        case .dailyTrendChart:
            DailyTrendChart(
                dailyFeedingOz: viewModel.dailyFeedingOz,
                dailyPumpingOz: viewModel.dailyPumpingOz
            )

        case .feedingHeatmapChart:
            FeedingHeatmapChart(feedingByHour: viewModel.feedingByHour)

        case .sleepPatternChart:
            SleepPatternChart(sleepBlocks: viewModel.sleepBlocks)

        case .diaperFrequencyChart:
            DiaperFrequencyChart(dailyDiaperCounts: viewModel.dailyDiaperCounts)

        case .monthlyComparison:
            if let comparison = viewModel.monthlyComparison {
                MonthlyComparisonCard(comparison: comparison)
            }
        }
    }

    private var fabItems: [FABItem] {
        [
            FABItem(label: theme.quickActionFeedingLabel, icon: theme.feedingTabIcon, color: .blue) {
                showFeedingForm = true
            },
            FABItem(label: theme.quickActionPumpingLabel, icon: theme.pumpingTabIcon, color: .orange) {
                showPumpingForm = true
            },
            FABItem(label: theme.quickActionSleepLabel, icon: theme.sleepTabIcon, color: .purple) {
                showSleepForm = true
            },
            FABItem(label: theme.quickActionDiaperLabel, icon: theme.diaperTabIcon, color: .teal) {
                showDiaperForm = true
            },
        ]
    }
}
