import SwiftUI
import Charts

struct PumpingWeekChart: View {
    let data: [PumpingViewModel.DailyPumpingData]

    struct ChartEntry: Identifiable {
        let id = UUID()
        let day: String
        let category: String
        let amount: Double
    }

    var chartEntries: [ChartEntry] {
        data.flatMap { day in
            [
                ChartEntry(day: day.displayDate, category: "To Be Consumed", amount: day.toBeConsumedOz),
                ChartEntry(day: day.displayDate, category: "Consumed", amount: day.consumedOz),
                ChartEntry(day: day.displayDate, category: "Frozen", amount: day.frozenOz),
            ]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This Week")
                .font(.headline)

            Chart(chartEntries) { entry in
                BarMark(
                    x: .value("Day", entry.day),
                    y: .value("Ounces", entry.amount)
                )
                .foregroundStyle(by: .value("Category", entry.category))
                .cornerRadius(4)
            }
            .chartForegroundStyleScale([
                "To Be Consumed": .orange,
                "Consumed": .blue,
                "Frozen": .cyan,
            ])
            .chartYAxisLabel("oz")
            .frame(height: 200)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
