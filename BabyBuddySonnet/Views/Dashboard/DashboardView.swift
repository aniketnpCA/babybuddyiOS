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

    // Timer management
    @State private var showStartTimer = false
    @State private var timerToStop: BabyTimer?
    @State private var timerDeleteConfirmation: BabyTimer?

    // Pre-filled times from stopped timer
    @State private var timerStartTime: Date?
    @State private var timerEndTime: Date?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                        if let error = viewModel.error {
                            ErrorBannerView(message: error) {
                                viewModel.error = nil
                            }
                        }

                        if !OfflineQueueService.shared.isOnline || OfflineQueueService.shared.hasPendingOperations {
                            OfflineStatusBanner()
                                .padding(.horizontal)
                        }

                        ChildProfileCard(
                            child: child,
                            latestWeight: viewModel.latestWeight,
                            latestHeight: viewModel.latestHeight,
                            latestHeadCircumference: viewModel.latestHeadCircumference
                        )
                        .padding(.horizontal)

                        ActiveTimersCard(
                            timers: viewModel.activeTimers,
                            onStop: { timer in
                                timerToStop = timer
                            },
                            onDelete: { timer in
                                timerDeleteConfirmation = timer
                            },
                            onStart: {
                                showStartTimer = true
                            }
                        )
                        .padding(.horizontal)

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

                        // More Activities
                        VStack(spacing: 8) {
                            HStack {
                                Text("More Activities")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }

                            NavigationLink {
                                TummyTimeView(childID: child.id)
                            } label: {
                                activityNavRow("Tummy Time", icon: "figure.play", color: .green)
                            }

                            NavigationLink {
                                TemperatureView(childID: child.id)
                            } label: {
                                activityNavRow("Temperature", icon: "thermometer.medium", color: .red)
                            }

                            NavigationLink {
                                NotesView(childID: child.id)
                            } label: {
                                activityNavRow("Notes", icon: "note.text", color: .yellow)
                            }
                        }
                        .padding(.horizontal)

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
            .refreshable {
                await reloadDashboard()
            }
            .task {
                await reloadDashboard()
            }
            .sheet(isPresented: $showFeedingForm, onDismiss: clearTimerTimes) {
                FeedingFormSheet(childID: child.id, initialStartTime: timerStartTime, initialEndTime: timerEndTime) {
                    await reloadDashboard()
                }
            }
            .sheet(isPresented: $showPumpingForm, onDismiss: clearTimerTimes) {
                PumpingFormSheet(childID: child.id, initialStartTime: timerStartTime, initialEndTime: timerEndTime) {
                    await reloadDashboard()
                }
            }
            .sheet(isPresented: $showSleepForm, onDismiss: clearTimerTimes) {
                SleepFormSheet(childID: child.id, initialStartTime: timerStartTime, initialEndTime: timerEndTime) {
                    await reloadDashboard()
                }
            }
            .sheet(isPresented: $showDiaperForm) {
                DiaperFormSheet(childID: child.id) {
                    await reloadDashboard()
                }
            }
            .sheet(isPresented: $showCustomize) {
                DashboardCustomizeSheet()
            }
            .sheet(isPresented: $showStartTimer) {
                StartTimerSheet(childID: child.id) { name in
                    await viewModel.startTimer(childID: child.id, name: name)
                }
            }
            .sheet(isPresented: $showTummyTimeForm, onDismiss: clearTimerTimes) {
                TummyTimeFormSheet(childID: child.id, initialStartTime: timerStartTime, initialEndTime: timerEndTime) {
                    await reloadDashboard()
                }
            }
            .sheet(isPresented: $showTemperatureForm) {
                TemperatureFormSheet(childID: child.id) {
                    await reloadDashboard()
                }
            }
            .sheet(isPresented: $showNoteForm) {
                NoteFormSheet(childID: child.id) {
                    await reloadDashboard()
                }
            }
            .sheet(item: $timerToStop) { timer in
                StopTimerSheet(
                    timer: timer,
                    childID: child.id,
                    onStop: {
                        await viewModel.stopTimer(timer)
                    },
                    onLogActivity: { activityType, start, end in
                        timerStartTime = start
                        timerEndTime = end
                        switch activityType {
                        case .feeding: showFeedingForm = true
                        case .sleep: showSleepForm = true
                        case .pumping: showPumpingForm = true
                        case .tummyTime: showTummyTimeForm = true
                        case .none: break
                        }
                    }
                )
            }
            .confirmationDialog(
                "Delete Timer",
                isPresented: Binding(
                    get: { timerDeleteConfirmation != nil },
                    set: { if !$0 { timerDeleteConfirmation = nil } }
                ),
                presenting: timerDeleteConfirmation
            ) { timer in
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteTimer(timer)
                    }
                }
            } message: { _ in
                Text("This timer will be permanently deleted.")
            }
        }
    }

    private func reloadDashboard() async {
        await viewModel.loadDashboard(childID: child.id, childName: child.displayName, birthDate: child.birthDate)
        await NotificationService.shared.rescheduleAll(childID: child.id)
    }

    private func clearTimerTimes() {
        timerStartTime = nil
        timerEndTime = nil
    }

    private func activityNavRow(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 28)
            Text(title)
                .font(.subheadline.weight(.medium))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @State private var showTummyTimeForm = false
    @State private var showTemperatureForm = false
    @State private var showNoteForm = false

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

        case .bmiChart:
            BMIChart(
                bmiMeasurements: viewModel.bmiMeasurements,
                birthDate: child.birthDate
            )

        case .feedingByTypeChart:
            FeedingByTypeChart(dailyFeedingByType: viewModel.dailyFeedingByType)

        case .feedingPatternChart:
            FeedingPatternChart(feedingScatterPoints: viewModel.feedingScatterPoints)

        case .feedingDurationsChart:
            FeedingDurationsChart(dailyFeedingDurations: viewModel.dailyFeedingDurations)

        case .feedingIntervalsChart:
            FeedingIntervalsChart(dailyFeedingIntervals: viewModel.dailyFeedingIntervals)

        case .sleepTotalsChart:
            SleepTotalsChart(
                dailySleepTotals: viewModel.dailySleepTotals,
                targetHours: settings.sleepTargetHours
            )

        case .pumpingAmountsChart:
            PumpingAmountsChart(dailyPumpingOz: viewModel.dailyPumpingOz)

        case .diaperIntervalsChart:
            DiaperIntervalsChart(diaperIntervals: viewModel.diaperIntervals)

        case .diaperLifetimesChart:
            DiaperLifetimesChart(diaperIntervals: viewModel.diaperIntervals)

        case .tummyTimeChart:
            TummyTimeChart(dailyTummyTimeMinutes: viewModel.dailyTummyTimeMinutes)

        case .temperatureChart:
            TemperatureChart(temperatureReadings: viewModel.temperaturePoints)
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
            FABItem(label: "Tummy Time", icon: "figure.play", color: .green) {
                showTummyTimeForm = true
            },
            FABItem(label: "Temperature", icon: "thermometer.medium", color: .red) {
                showTemperatureForm = true
            },
            FABItem(label: "Note", icon: "note.text", color: .yellow) {
                showNoteForm = true
            },
        ]
    }
}
