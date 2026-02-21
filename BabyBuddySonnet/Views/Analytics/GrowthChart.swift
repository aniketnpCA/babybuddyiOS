import SwiftUI
import Charts

struct GrowthChart: View {
    let weightMeasurements: [WeightMeasurement]
    let heightMeasurements: [HeightMeasurement]
    let headCircumferenceMeasurements: [HeadCircumferenceMeasurement]
    let birthDate: String

    private var ageInMonths: Int {
        guard let date = DateFormatting.parseDate(birthDate) else { return 0 }
        let components = Calendar.current.dateComponents([.month], from: date, to: Date())
        return min(components.month ?? 0, 24)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Growth")
                .font(.title2.bold())

            if !weightMeasurements.isEmpty {
                weightChart
            }
            if !heightMeasurements.isEmpty {
                heightChart
            }
            if !headCircumferenceMeasurements.isEmpty {
                headCircumferenceChart
            }

            if weightMeasurements.isEmpty && heightMeasurements.isEmpty && headCircumferenceMeasurements.isEmpty {
                Text("No growth measurements yet. Tap + to log one.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            }
        }
    }

    // MARK: - Weight Chart

    private var weightChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weight")
                .font(.headline)

            Chart {
                // WHO percentile bands
                ForEach(0...min(ageInMonths + 2, 24), id: \.self) { month in
                    let p = WHOGrowthData.weightPercentiles(atMonth: month)
                    AreaMark(
                        x: .value("Month", month),
                        yStart: .value("P3", p.p3),
                        yEnd: .value("P97", p.p97)
                    )
                    .foregroundStyle(.blue.opacity(0.08))

                    LineMark(
                        x: .value("Month", month),
                        y: .value("P50", p.p50),
                        series: .value("Series", "P50")
                    )
                    .foregroundStyle(.blue.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                    LineMark(
                        x: .value("Month", month),
                        y: .value("P3", p.p3),
                        series: .value("Series", "P3")
                    )
                    .foregroundStyle(.blue.opacity(0.15))
                    .lineStyle(StrokeStyle(lineWidth: 0.5))

                    LineMark(
                        x: .value("Month", month),
                        y: .value("P97", p.p97),
                        series: .value("Series", "P97")
                    )
                    .foregroundStyle(.blue.opacity(0.15))
                    .lineStyle(StrokeStyle(lineWidth: 0.5))
                }

                // Baby's data points
                ForEach(weightMeasurements) { m in
                    let month = monthsSinceBirth(m.date)
                    PointMark(
                        x: .value("Month", month),
                        y: .value("Weight", m.weightInKg)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(40)

                    LineMark(
                        x: .value("Month", month),
                        y: .value("Weight", m.weightInKg),
                        series: .value("Series", "Baby")
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .chartXAxisLabel("Age (months)")
            .chartYAxisLabel("kg")
            .frame(height: 200)

            HStack(spacing: 12) {
                legendItem(color: .blue, label: "Baby")
                legendItem(color: .blue.opacity(0.3), label: "P50", dashed: true)
                legendItem(color: .blue.opacity(0.08), label: "P3–P97", filled: true)
            }
            .font(.caption2)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Height Chart

    private var heightChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Length / Height")
                .font(.headline)

            Chart {
                ForEach(0...min(ageInMonths + 2, 24), id: \.self) { month in
                    let p = WHOGrowthData.lengthPercentiles(atMonth: month)
                    AreaMark(
                        x: .value("Month", month),
                        yStart: .value("P3", p.p3),
                        yEnd: .value("P97", p.p97)
                    )
                    .foregroundStyle(.green.opacity(0.08))

                    LineMark(
                        x: .value("Month", month),
                        y: .value("P50", p.p50),
                        series: .value("Series", "P50")
                    )
                    .foregroundStyle(.green.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }

                ForEach(heightMeasurements) { m in
                    let month = monthsSinceBirth(m.date)
                    PointMark(
                        x: .value("Month", month),
                        y: .value("Height", m.height)
                    )
                    .foregroundStyle(.green)
                    .symbolSize(40)

                    LineMark(
                        x: .value("Month", month),
                        y: .value("Height", m.height),
                        series: .value("Series", "Baby")
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .chartXAxisLabel("Age (months)")
            .chartYAxisLabel("cm")
            .frame(height: 200)

            HStack(spacing: 12) {
                legendItem(color: .green, label: "Baby")
                legendItem(color: .green.opacity(0.3), label: "P50", dashed: true)
                legendItem(color: .green.opacity(0.08), label: "P3–P97", filled: true)
            }
            .font(.caption2)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Head Circumference Chart

    private var headCircumferenceChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Head Circumference")
                .font(.headline)

            Chart {
                ForEach(0...min(ageInMonths + 2, 24), id: \.self) { month in
                    let p = WHOGrowthData.headCircumferencePercentiles(atMonth: month)
                    AreaMark(
                        x: .value("Month", month),
                        yStart: .value("P3", p.p3),
                        yEnd: .value("P97", p.p97)
                    )
                    .foregroundStyle(.purple.opacity(0.08))

                    LineMark(
                        x: .value("Month", month),
                        y: .value("P50", p.p50),
                        series: .value("Series", "P50")
                    )
                    .foregroundStyle(.purple.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }

                ForEach(headCircumferenceMeasurements) { m in
                    let month = monthsSinceBirth(m.date)
                    PointMark(
                        x: .value("Month", month),
                        y: .value("HC", m.headCircumference)
                    )
                    .foregroundStyle(.purple)
                    .symbolSize(40)

                    LineMark(
                        x: .value("Month", month),
                        y: .value("HC", m.headCircumference),
                        series: .value("Series", "Baby")
                    )
                    .foregroundStyle(.purple)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .chartXAxisLabel("Age (months)")
            .chartYAxisLabel("cm")
            .frame(height: 200)

            HStack(spacing: 12) {
                legendItem(color: .purple, label: "Baby")
                legendItem(color: .purple.opacity(0.3), label: "P50", dashed: true)
                legendItem(color: .purple.opacity(0.08), label: "P3–P97", filled: true)
            }
            .font(.caption2)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func monthsSinceBirth(_ dateString: String) -> Double {
        guard let birth = DateFormatting.parseDate(birthDate),
              let date = DateFormatting.parseDate(dateString)
        else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: birth, to: date).day ?? 0
        return Double(days) / 30.44 // average days per month
    }

    private func legendItem(color: Color, label: String, dashed: Bool = false, filled: Bool = false) -> some View {
        HStack(spacing: 4) {
            if filled {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 14, height: 8)
            } else {
                Rectangle()
                    .fill(color)
                    .frame(width: 14, height: dashed ? 1 : 2)
            }
            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}
