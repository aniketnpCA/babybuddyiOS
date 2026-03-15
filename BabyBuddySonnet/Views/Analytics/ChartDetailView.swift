import SwiftUI

/// A full-screen detail view for any chart. Shows the chart at a larger size
/// with a title and optional summary stats.
struct ChartDetailView<Chart: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let chart: () -> Chart

    init(_ title: String, subtitle: String? = nil, @ViewBuilder chart: @escaping () -> Chart) {
        self.title = title
        self.subtitle = subtitle
        self.chart = chart
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                chart()
                    .frame(minHeight: 300)
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
