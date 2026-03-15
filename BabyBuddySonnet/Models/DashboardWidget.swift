import Foundation

nonisolated enum DashboardWidget: String, CaseIterable, Codable, Sendable, Identifiable {
    case feedingWeeklyChart
    case pumpingWeeklyChart
    case growthChart
    case dailyTrendChart
    case feedingHeatmapChart
    case sleepPatternChart
    case diaperFrequencyChart
    case monthlyComparison

    var id: String { rawValue }

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
        }
    }
}
