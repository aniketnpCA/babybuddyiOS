import SwiftUI

struct FeedingProgressCard: View {
    let chartData: FeedingViewModel.CumulativeChartData

    var body: some View {
        FeedingCumulativeChart(data: chartData)
    }
}
