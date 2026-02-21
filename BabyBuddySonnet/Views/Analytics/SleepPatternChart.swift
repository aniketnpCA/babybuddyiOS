import SwiftUI
import Charts

struct SleepPatternChart: View {
    let sleepBlocks: [(date: String, startHour: Double, endHour: Double, isNap: Bool)]

    private var sortedDates: [String] {
        Array(Set(sleepBlocks.map(\.date))).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sleep Patterns")
                    .font(.headline)
                Spacer()
                Text("Last 7 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if sleepBlocks.isEmpty {
                Text("No sleep data for the past week.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                Chart {
                    ForEach(Array(sleepBlocks.enumerated()), id: \.offset) { _, block in
                        let displayDate = shortDate(block.date)
                        // Handle sleep that crosses midnight
                        if block.endHour < block.startHour {
                            // Part before midnight
                            BarMark(
                                xStart: .value("Start", block.startHour),
                                xEnd: .value("End", 24.0),
                                y: .value("Date", displayDate)
                            )
                            .foregroundStyle(block.isNap ? Color.purple.opacity(0.5) : Color.purple)
                            .cornerRadius(2)

                            // Part after midnight
                            BarMark(
                                xStart: .value("Start", 0.0),
                                xEnd: .value("End", block.endHour),
                                y: .value("Date", displayDate)
                            )
                            .foregroundStyle(block.isNap ? Color.purple.opacity(0.5) : Color.purple)
                            .cornerRadius(2)
                        } else {
                            BarMark(
                                xStart: .value("Start", block.startHour),
                                xEnd: .value("End", block.endHour),
                                y: .value("Date", displayDate)
                            )
                            .foregroundStyle(block.isNap ? Color.purple.opacity(0.5) : Color.purple)
                            .cornerRadius(2)
                        }
                    }
                }
                .chartXScale(domain: 0...24)
                .chartXAxis {
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
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }
                .frame(height: 200)
            }

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.purple)
                        .frame(width: 14, height: 8)
                    Text("Night sleep")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.purple.opacity(0.5))
                        .frame(width: 14, height: 8)
                    Text("Nap")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func shortDate(_ dateString: String) -> String {
        guard let date = DateFormatting.parseDate(dateString) else { return dateString }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
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
