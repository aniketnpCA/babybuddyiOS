import SwiftUI

struct AnalyticsView: View {
    let child: Child

    @State private var viewModel = AnalyticsViewModel()
    @State private var showingGrowthForm = false
    @State private var showingAIChat = false
    @State private var editingGrowth: GrowthEditTarget?
    @State private var showingEditGrowth = false

    // Section expansion state — start most collapsed to reduce initial render complexity
    @State private var growthExpanded = false
    @State private var feedingExpanded = true
    @State private var sleepExpanded = false
    @State private var diapersExpanded = false
    @State private var pumpingExpanded = false
    @State private var tummyTimeExpanded = false
    @State private var temperatureExpanded = false

    private let settings = SettingsService.shared

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                if viewModel.isLoading && viewModel.recentFeedings.isEmpty {
                    ProgressView("Loading analytics...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            aiButton

                            if let comparison = viewModel.monthlyComparison {
                                MonthlyComparisonCard(comparison: comparison)
                            }

                            // Growth Section
                            if hasGrowthData {
                                analyticsSection("Growth", systemImage: "chart.line.uptrend.xyaxis", isExpanded: $growthExpanded) {
                                    tappableChart("Growth Charts", subtitle: "Weight, height & head circumference with WHO percentiles") {
                                        GrowthChart(
                                            weightMeasurements: viewModel.weightMeasurements,
                                            heightMeasurements: viewModel.heightMeasurements,
                                            headCircumferenceMeasurements: viewModel.headCircumferenceMeasurements,
                                            birthDate: child.birthDate,
                                            childSex: settings.childSex
                                        )
                                    }

                                    if !viewModel.bmiMeasurements.isEmpty {
                                        tappableChart("BMI Chart", subtitle: "BMI measurements with WHO percentiles") {
                                            BMIChart(
                                                bmiMeasurements: viewModel.bmiMeasurements,
                                                birthDate: child.birthDate
                                            )
                                        }
                                    }

                                    // Measurement history
                                    if !viewModel.weightMeasurements.isEmpty {
                                        measurementHistorySection("Weight", measurements: viewModel.weightMeasurements) { m in
                                            editingGrowth = .weight(m)
                                            showingEditGrowth = true
                                        }
                                    }

                                    if !viewModel.heightMeasurements.isEmpty {
                                        measurementHistorySection("Height", measurements: viewModel.heightMeasurements) { m in
                                            editingGrowth = .height(m)
                                            showingEditGrowth = true
                                        }
                                    }

                                    if !viewModel.headCircumferenceMeasurements.isEmpty {
                                        measurementHistorySection("Head Circ.", measurements: viewModel.headCircumferenceMeasurements) { m in
                                            editingGrowth = .headCircumference(m)
                                            showingEditGrowth = true
                                        }
                                    }
                                }
                            }

                            // Feeding Section
                            analyticsSection("Feeding", systemImage: "cup.and.saucer.fill", isExpanded: $feedingExpanded) {
                                tappableChart("Daily Trends", subtitle: "30-day feeding & pumping trends") {
                                    DailyTrendChart(
                                        dailyFeedingOz: viewModel.dailyFeedingOz,
                                        dailyPumpingOz: viewModel.dailyPumpingOz
                                    )
                                }

                                tappableChart("Feeding by Type", subtitle: "Daily breakdown by milk type") {
                                    FeedingByTypeChart(
                                        dailyFeedingByType: viewModel.dailyFeedingByType
                                    )
                                }

                                tappableChart("Feeding Heatmap", subtitle: "Feeding frequency by hour of day") {
                                    FeedingHeatmapChart(
                                        feedingByHour: viewModel.feedingByHour
                                    )
                                }

                                tappableChart("Feeding Pattern", subtitle: "Scatter plot of feeding times by hour") {
                                    FeedingPatternChart(
                                        feedingScatterPoints: viewModel.feedingScatterPoints
                                    )
                                }

                                tappableChart("Feeding Durations", subtitle: "Average feeding duration per day") {
                                    FeedingDurationsChart(
                                        dailyFeedingDurations: viewModel.dailyFeedingDurations
                                    )
                                }

                                tappableChart("Feeding Intervals", subtitle: "Average hours between feedings") {
                                    FeedingIntervalsChart(
                                        dailyFeedingIntervals: viewModel.dailyFeedingIntervals
                                    )
                                }
                            }

                            // Sleep Section
                            analyticsSection("Sleep", systemImage: "moon.fill", isExpanded: $sleepExpanded) {
                                tappableChart("Sleep Patterns", subtitle: "Sleep blocks over the last 7 days") {
                                    SleepPatternChart(
                                        sleepBlocks: viewModel.sleepBlocks
                                    )
                                }

                                tappableChart("Sleep Totals", subtitle: "Daily sleep hours vs target") {
                                    SleepTotalsChart(
                                        dailySleepTotals: viewModel.dailySleepTotals,
                                        targetHours: settings.sleepTargetHours
                                    )
                                }
                            }

                            // Diapers Section
                            analyticsSection("Diapers", systemImage: "drop.fill", isExpanded: $diapersExpanded) {
                                tappableChart("Diaper Frequency", subtitle: "Diaper changes over the last 14 days") {
                                    DiaperFrequencyChart(
                                        dailyDiaperCounts: viewModel.dailyDiaperCounts
                                    )
                                }

                                tappableChart("Diaper Intervals", subtitle: "Time between diaper changes") {
                                    DiaperIntervalsChart(
                                        diaperIntervals: viewModel.diaperIntervals
                                    )
                                }

                                tappableChart("Diaper Lifetimes", subtitle: "Distribution of diaper change intervals") {
                                    DiaperLifetimesChart(
                                        diaperIntervals: viewModel.diaperIntervals
                                    )
                                }
                            }

                            // Pumping Section
                            if !viewModel.recentPumping.isEmpty {
                                analyticsSection("Pumping", systemImage: "drop.circle.fill", isExpanded: $pumpingExpanded) {
                                    tappableChart("Pumping Amounts", subtitle: "Daily pumping volume trend") {
                                        PumpingAmountsChart(
                                            dailyPumpingOz: viewModel.dailyPumpingOz
                                        )
                                    }
                                }
                            }

                            // Tummy Time Section
                            if !viewModel.recentTummyTimes.isEmpty {
                                analyticsSection("Tummy Time", systemImage: "figure.play", isExpanded: $tummyTimeExpanded) {
                                    tappableChart("Tummy Time", subtitle: "Daily tummy time in minutes") {
                                        TummyTimeChart(
                                            dailyTummyTimeMinutes: viewModel.dailyTummyTimeMinutes
                                        )
                                    }
                                }
                            }

                            // Temperature Section
                            if !viewModel.recentTemperatures.isEmpty {
                                analyticsSection("Temperature", systemImage: "thermometer.medium", isExpanded: $temperatureExpanded) {
                                    tappableChart("Temperature", subtitle: "Temperature readings over time") {
                                        TemperatureChart(
                                            temperatureReadings: viewModel.temperaturePoints
                                        )
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.loadAll(childID: child.id, birthDate: child.birthDate)
                    }
                }

                FloatingActionButton(color: .teal) {
                    showingGrowthForm = true
                }
            }
            .navigationTitle("Analytics")
            .task {
                await viewModel.loadAll(childID: child.id, birthDate: child.birthDate)
            }
            .sheet(isPresented: $showingGrowthForm) {
                GrowthFormSheet(
                    childID: child.id,
                    viewModel: viewModel,
                    onSave: {
                        Task {
                            await viewModel.loadAll(childID: child.id, birthDate: child.birthDate)
                        }
                    }
                )
            }
            .sheet(isPresented: $showingAIChat) {
                AIChatSheet(
                    viewModel: viewModel,
                    childAge: child.age,
                    childID: child.id
                )
            }
            .sheet(isPresented: $showingEditGrowth, onDismiss: { editingGrowth = nil }) {
                if let target = editingGrowth {
                    GrowthFormSheet(
                        childID: child.id,
                        viewModel: viewModel,
                        editing: target,
                        onSave: {
                            Task {
                                await viewModel.loadAll(childID: child.id, birthDate: child.birthDate)
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Helpers

    private var hasGrowthData: Bool {
        !viewModel.weightMeasurements.isEmpty ||
        !viewModel.heightMeasurements.isEmpty ||
        !viewModel.headCircumferenceMeasurements.isEmpty ||
        !viewModel.bmiMeasurements.isEmpty
    }

    /// Wraps a chart in a NavigationLink that pushes a full-screen detail view.
    /// The chart is shown as a preview in the list and as a larger interactive
    /// view on the detail screen.
    private func tappableChart<C: View>(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder chart: @escaping () -> C
    ) -> some View {
        NavigationLink {
            ChartDetailView(title, subtitle: subtitle, chart: chart)
        } label: {
            chart()
                .allowsHitTesting(false) // let the NavigationLink handle taps
        }
        .buttonStyle(.plain)
    }

    private func analyticsSection<Content: View>(
        _ title: String,
        systemImage: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: systemImage)
                        .foregroundStyle(.secondary)
                    Text(title)
                        .font(.title3.bold())
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded.wrappedValue {
                content()
            }
        }
    }

    private func measurementHistorySection(_ title: String, measurements: [WeightMeasurement], onEdit: @escaping (WeightMeasurement) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(title) History")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ForEach(measurements.prefix(5)) { m in
                Button {
                    onEdit(m)
                } label: {
                    HStack {
                        Text(m.date)
                            .font(.caption)
                        Spacer()
                        Text(String(format: "%.1f lbs", m.weightInLbs))
                            .font(.caption.monospacedDigit())
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func measurementHistorySection(_ title: String, measurements: [HeightMeasurement], onEdit: @escaping (HeightMeasurement) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(title) History")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ForEach(measurements.prefix(5)) { m in
                Button {
                    onEdit(m)
                } label: {
                    HStack {
                        Text(m.date)
                            .font(.caption)
                        Spacer()
                        Text(String(format: "%.1f cm", m.height))
                            .font(.caption.monospacedDigit())
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func measurementHistorySection(_ title: String, measurements: [HeadCircumferenceMeasurement], onEdit: @escaping (HeadCircumferenceMeasurement) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(title) History")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ForEach(measurements.prefix(5)) { m in
                Button {
                    onEdit(m)
                } label: {
                    HStack {
                        Text(m.date)
                            .font(.caption)
                        Spacer()
                        Text(String(format: "%.1f cm", m.headCircumference))
                            .font(.caption.monospacedDigit())
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var aiButton: some View {
        Button {
            showingAIChat = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.body.bold())
                Text("Ask AI")
                    .font(.subheadline.bold())
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
