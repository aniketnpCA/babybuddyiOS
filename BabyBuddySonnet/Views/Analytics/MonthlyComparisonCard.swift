import SwiftUI

struct MonthlyComparisonCard: View {
    let comparison: MonthlyComparison

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Monthly Comparison")
                    .font(.headline)
                Spacer()
                Text("This month vs last")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                comparisonTile(
                    title: "Avg Daily Feeding",
                    current: comparison.avgDailyFeedingOzThisMonth,
                    previous: comparison.avgDailyFeedingOzLastMonth,
                    unit: "oz",
                    icon: "drop.fill",
                    color: .blue
                )

                comparisonTile(
                    title: "Avg Daily Sleep",
                    current: comparison.avgDailySleepHoursThisMonth,
                    previous: comparison.avgDailySleepHoursLastMonth,
                    unit: "hrs",
                    icon: "moon.fill",
                    color: .purple
                )

                comparisonTile(
                    title: "Avg Daily Diapers",
                    current: comparison.avgDailyDiapersThisMonth,
                    previous: comparison.avgDailyDiapersLastMonth,
                    unit: "",
                    icon: "circle.dotted",
                    color: .green
                )

                comparisonTile(
                    title: "Total Pumped",
                    current: comparison.totalPumpedThisMonth,
                    previous: comparison.totalPumpedLastMonth,
                    unit: "oz",
                    icon: "drop.triangle.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func comparisonTile(
        title: String,
        current: Double,
        previous: Double,
        unit: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(formatValue(current))
                    .font(.title3.bold())
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            trendIndicator(current: current, previous: previous)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func trendIndicator(current: Double, previous: Double) -> some View {
        Group {
            if previous == 0 && current == 0 {
                Text("—")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if previous == 0 {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up")
                    Text("New")
                }
                .font(.caption2)
                .foregroundStyle(.green)
            } else {
                let change = ((current - previous) / previous) * 100
                HStack(spacing: 2) {
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                    Text("\(abs(Int(change)))%")
                }
                .font(.caption2)
                .foregroundStyle(change >= 0 ? .green : .red)
            }
        }
    }

    private func formatValue(_ value: Double) -> String {
        if value >= 100 {
            return String(format: "%.0f", value)
        } else if value >= 10 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}
