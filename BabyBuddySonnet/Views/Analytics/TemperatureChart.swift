import SwiftUI
import Charts

struct TemperatureChart: View {
    let temperatureReadings: [(date: Date, value: Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Temperature")
                    .font(.headline)
                Spacer()
                Text("Last 30 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if temperatureReadings.isEmpty {
                Text("No temperature data available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                Chart {
                    // Normal range band (97.0 - 100.4 F)
                    RectangleMark(
                        yStart: .value("Low Normal", 97.0),
                        yEnd: .value("High Normal", 100.4)
                    )
                    .foregroundStyle(.green.opacity(0.08))

                    // Fever threshold
                    RuleMark(y: .value("Fever", 100.4))
                        .foregroundStyle(.red.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("100.4\u{00B0}F")
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }

                    ForEach(temperatureReadings, id: \.date) { reading in
                        PointMark(
                            x: .value("Date", reading.date),
                            y: .value("Temp", reading.value)
                        )
                        .foregroundStyle(reading.value >= 100.4 ? .red : .blue)
                        .symbolSize(30)

                        LineMark(
                            x: .value("Date", reading.date),
                            y: .value("Temp", reading.value)
                        )
                        .foregroundStyle(.blue.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                    }
                }
                .chartYAxisLabel("\u{00B0}F")
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                            .foregroundStyle(.white.opacity(0.1))
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
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
                .frame(height: 200)

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 6, height: 6)
                        Text("Normal")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.red)
                            .frame(width: 6, height: 6)
                        Text("Fever")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(.green.opacity(0.3))
                            .frame(width: 14, height: 8)
                        Text("Normal Range")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
