import SwiftUI
import Charts

struct DiaperLifetimesChart: View {
    let diaperIntervals: [(date: Date, hours: Double)]

    private struct Bucket: Identifiable {
        let id: Int
        let label: String
        let count: Int
    }

    private var buckets: [Bucket] {
        guard !diaperIntervals.isEmpty else { return [] }
        // Bucket into 1-hour bins from 0-12+
        let maxBucket = 12
        var counts = [Int](repeating: 0, count: maxBucket + 1)
        for interval in diaperIntervals {
            let bin = min(Int(interval.hours), maxBucket)
            counts[bin] += 1
        }
        return counts.enumerated().compactMap { index, count in
            guard count > 0 || index <= 8 else { return nil }
            let label = index == maxBucket ? "\(maxBucket)+" : "\(index)"
            return Bucket(id: index, label: label, count: count)
        }
    }

    /// Bucket label matching the median value — must match an existing bucket label
    /// to avoid Swift Charts categorical mismatch issues
    private var medianBucketLabel: String {
        let maxBucket = 12
        let bin = min(Int(medianHours), maxBucket)
        return bin == maxBucket ? "\(maxBucket)+" : "\(bin)"
    }

    private var medianHours: Double {
        let sorted = diaperIntervals.map(\.hours).sorted()
        guard !sorted.isEmpty else { return 0 }
        let mid = sorted.count / 2
        return sorted.count.isMultiple(of: 2)
            ? (sorted[mid - 1] + sorted[mid]) / 2
            : sorted[mid]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Diaper Lifetimes")
                    .font(.headline)
                Spacer()
                Text("Last 30 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if diaperIntervals.isEmpty {
                Text("No diaper data available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                Chart {
                    ForEach(buckets) { bucket in
                        BarMark(
                            x: .value("Hours", bucket.label),
                            y: .value("Count", bucket.count)
                        )
                        .foregroundStyle(Color.jayTummyTimeFallback.gradient)
                        .cornerRadius(3)
                    }

                    // Use a matching bucket label for the RuleMark categorical position
                    RuleMark(x: .value("Median", medianBucketLabel))
                        .foregroundStyle(Color.jayPumpingFallback)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        .annotation(position: .top, alignment: .center) {
                            Text("Median: \(String(format: "%.1f", medianHours))h")
                                .font(.caption2)
                                .foregroundStyle(Color.jayPumpingFallback)
                        }
                }
                .chartXAxisLabel("Hours between changes")
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
                .frame(height: 200)

                Text("Distribution of time between diaper changes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
