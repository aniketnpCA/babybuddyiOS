import Foundation

nonisolated enum DashboardWidgetCategory: String, CaseIterable, Sendable {
    case feeding = "Feeding"
    case sleep = "Sleep"
    case diaper = "Diaper"
    case pumping = "Pumping"
    case growth = "Growth"
    case tummyTime = "Tummy Time"
    case temperature = "Temperature"
    case overview = "Overview"
}

nonisolated enum DashboardWidget: String, CaseIterable, Codable, Sendable, Identifiable {
    // Existing
    case feedingWeeklyChart
    case pumpingWeeklyChart
    case growthChart
    case dailyTrendChart
    case feedingHeatmapChart
    case sleepPatternChart
    case diaperFrequencyChart
    case monthlyComparison

    // New from Analytics
    case bmiChart
    case feedingByTypeChart
    case feedingPatternChart
    case feedingDurationsChart
    case feedingIntervalsChart
    case sleepTotalsChart
    case pumpingAmountsChart
    case diaperIntervalsChart
    case diaperLifetimesChart
    case tummyTimeChart
    case temperatureChart

    var id: String { rawValue }

    var category: DashboardWidgetCategory {
        switch self {
        case .feedingWeeklyChart, .feedingHeatmapChart, .feedingByTypeChart,
             .feedingPatternChart, .feedingDurationsChart, .feedingIntervalsChart:
            return .feeding
        case .sleepPatternChart, .sleepTotalsChart:
            return .sleep
        case .diaperFrequencyChart, .diaperIntervalsChart, .diaperLifetimesChart:
            return .diaper
        case .pumpingWeeklyChart, .pumpingAmountsChart:
            return .pumping
        case .growthChart, .bmiChart:
            return .growth
        case .tummyTimeChart:
            return .tummyTime
        case .temperatureChart:
            return .temperature
        case .dailyTrendChart, .monthlyComparison:
            return .overview
        }
    }

    var displayName: String {
        switch self {
        case .feedingWeeklyChart: "Feeding Weekly"
        case .pumpingWeeklyChart: "Pumping Weekly"
        case .growthChart: "Growth Charts"
        case .dailyTrendChart: "Daily Trends"
        case .feedingHeatmapChart: "Feeding Heatmap"
        case .sleepPatternChart: "Sleep Patterns"
        case .diaperFrequencyChart: "Diaper Frequency"
        case .monthlyComparison: "Monthly Comparison"
        case .bmiChart: "BMI Chart"
        case .feedingByTypeChart: "Feeding by Type"
        case .feedingPatternChart: "Feeding Pattern"
        case .feedingDurationsChart: "Feeding Durations"
        case .feedingIntervalsChart: "Feeding Intervals"
        case .sleepTotalsChart: "Sleep Totals"
        case .pumpingAmountsChart: "Pumping Amounts"
        case .diaperIntervalsChart: "Diaper Intervals"
        case .diaperLifetimesChart: "Diaper Lifetimes"
        case .tummyTimeChart: "Tummy Time"
        case .temperatureChart: "Temperature"
        }
    }

    var icon: String {
        switch self {
        case .feedingWeeklyChart: "chart.bar.fill"
        case .pumpingWeeklyChart: "drop.fill"
        case .growthChart: "chart.line.uptrend.xyaxis"
        case .dailyTrendChart: "chart.xyaxis.line"
        case .feedingHeatmapChart: "square.grid.3x3.fill"
        case .sleepPatternChart: "moon.fill"
        case .diaperFrequencyChart: "chart.bar.xaxis"
        case .monthlyComparison: "arrow.left.arrow.right"
        case .bmiChart: "figure.stand"
        case .feedingByTypeChart: "chart.bar.xaxis.ascending"
        case .feedingPatternChart: "chart.dots.scatter"
        case .feedingDurationsChart: "timer"
        case .feedingIntervalsChart: "clock.arrow.2.circlepath"
        case .sleepTotalsChart: "bed.double.fill"
        case .pumpingAmountsChart: "drop.triangle.fill"
        case .diaperIntervalsChart: "clock"
        case .diaperLifetimesChart: "chart.pie.fill"
        case .tummyTimeChart: "figure.play"
        case .temperatureChart: "thermometer.medium"
        }
    }

    var description: String {
        switch self {
        case .feedingWeeklyChart: "Bar chart of daily feeding totals vs goal"
        case .pumpingWeeklyChart: "Stacked bars by milk category"
        case .growthChart: "Weight, height & head with WHO percentiles"
        case .dailyTrendChart: "30-day feeding & pumping trends"
        case .feedingHeatmapChart: "Feeding frequency by hour of day"
        case .sleepPatternChart: "Sleep blocks over the last 7 days"
        case .diaperFrequencyChart: "Diaper changes over the last 14 days"
        case .monthlyComparison: "This month vs last month metrics"
        case .bmiChart: "BMI measurements with WHO percentiles"
        case .feedingByTypeChart: "Daily breakdown by milk type"
        case .feedingPatternChart: "Scatter plot of feeding times by hour"
        case .feedingDurationsChart: "Average feeding duration per day"
        case .feedingIntervalsChart: "Average hours between feedings"
        case .sleepTotalsChart: "Daily sleep hours vs target"
        case .pumpingAmountsChart: "Daily pumping volume trend"
        case .diaperIntervalsChart: "Time between diaper changes"
        case .diaperLifetimesChart: "Distribution of diaper change intervals"
        case .tummyTimeChart: "Daily tummy time in minutes"
        case .temperatureChart: "Temperature readings over time"
        }
    }

    /// Grouped by category for the customize sheet
    static var groupedByCategory: [(category: DashboardWidgetCategory, widgets: [DashboardWidget])] {
        DashboardWidgetCategory.allCases.compactMap { category in
            let widgets = DashboardWidget.allCases.filter { $0.category == category }
            return widgets.isEmpty ? nil : (category: category, widgets: widgets)
        }
    }
}
