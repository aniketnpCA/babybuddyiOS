import SwiftUI
import Charts

struct FeedingPatternChart: View {
    let feedingScatterPoints: [(date: Date, hourOfDay: Double, type: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Feeding Schedule")
                    .font(.headline)
                Spacer()
                Text("Last 30 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if feedingScatterPoints.isEmpty {
                Text("No feeding data available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                Chart {
                    ForEach(Array(feedingScatterPoints.enumerated()), id: \.offset) { _, point in
                        PointMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Time", point.hourOfDay)
                        )
                        .foregroundStyle(by: .value("Type", displayType(point.type)))
                        .symbolSize(20)
                        .opacity(0.7)
                    }
                }
                .chartForegroundStyleScale([
                    "Breast Milk": Color.blue,
                    "Formula": Color.orange,
                    "Fortified": Color.purple,
                    "Solid Food": Color.green,
                ])
                .chartYScale(domain: 0...24)
                .chartYAxis {
                    AxisMarks(values: [0, 6, 12, 18, 24]) { value in
                        AxisGridLine()
                            .foregroundStyle(.white.opacity(0.1))
                        AxisTick()
                        AxisValueLabel {
                            if let h = value.as(Double.self) {
                                Text(timeLabel(Int(h)))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                            .foregroundStyle(.white.opacity(0.1))
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .font(.caption2)
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

    private func displayType(_ raw: String) -> String {
        FeedingType(rawValue: raw)?.displayName ?? raw
    }

    private func timeLabel(_ hour: Int) -> String {
        switch hour {
        case 0, 24: return "12a"
        case 6: return "6a"
        case 12: return "12p"
        case 18: return "6p"
        default: return "\(hour)"
        }
    }
}
