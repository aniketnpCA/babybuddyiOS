import SwiftUI
import Charts

struct FeedingByTypeChart: View {
    let dailyFeedingByType: [(date: String, breastMilk: Double, formula: Double, fortified: Double)]

    private var last14Days: [(date: String, breastMilk: Double, formula: Double, fortified: Double)] {
        Array(dailyFeedingByType.suffix(14))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Feeding by Type")
                    .font(.headline)
                Spacer()
                Text("Last 14 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if last14Days.isEmpty || last14Days.allSatisfy({ $0.breastMilk == 0 && $0.formula == 0 && $0.fortified == 0 }) {
                Text("No bottle feeding data available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                Chart {
                    ForEach(last14Days, id: \.date) { day in
                        let displayDate = shortDate(day.date)

                        if day.breastMilk > 0 {
                            BarMark(
                                x: .value("Date", displayDate),
                                y: .value("oz", day.breastMilk)
                            )
                            .foregroundStyle(by: .value("Type", "Breast Milk"))
                        }

                        if day.formula > 0 {
                            BarMark(
                                x: .value("Date", displayDate),
                                y: .value("oz", day.formula)
                            )
                            .foregroundStyle(by: .value("Type", "Formula"))
                        }

                        if day.fortified > 0 {
                            BarMark(
                                x: .value("Date", displayDate),
                                y: .value("oz", day.fortified)
                            )
                            .foregroundStyle(by: .value("Type", "Fortified"))
                        }
                    }
                }
                .chartForegroundStyleScale([
                    "Breast Milk": Color.blue,
                    "Formula": Color.orange,
                    "Fortified": Color.purple,
                ])
                .chartYAxisLabel("oz")
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                            .foregroundStyle(.white.opacity(0.1))
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
                .frame(height: 200)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func shortDate(_ dateString: String) -> String {
        guard let date = DateFormatting.parseDate(dateString) else { return dateString }
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}
