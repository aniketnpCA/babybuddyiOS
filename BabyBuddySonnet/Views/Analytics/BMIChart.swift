import SwiftUI
import Charts

struct BMIChart: View {
    let bmiMeasurements: [BMIMeasurement]
    let birthDate: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BMI")
                .font(.headline)

            if bmiMeasurements.isEmpty {
                Text("No BMI data available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                Chart {
                    ForEach(bmiMeasurements) { m in
                        let month = monthsSinceBirth(m.date)
                        LineMark(
                            x: .value("Month", month),
                            y: .value("BMI", m.bmi),
                            series: .value("Series", "BMI")
                        )
                        .foregroundStyle(Color.jayDiaperFallback)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        PointMark(
                            x: .value("Month", month),
                            y: .value("BMI", m.bmi)
                        )
                        .foregroundStyle(Color.jayDiaperFallback)
                        .symbolSize(40)
                    }
                }
                .chartXAxisLabel("Age (months)")
                .chartYAxisLabel("kg/m²")
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                            .foregroundStyle(.white.opacity(0.1))
                        AxisTick()
                        AxisValueLabel()
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
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func monthsSinceBirth(_ dateString: String) -> Double {
        guard let birth = DateFormatting.parseDate(birthDate),
              let date = DateFormatting.parseDate(dateString)
        else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: birth, to: date).day ?? 0
        return Double(days) / 30.44
    }
}
