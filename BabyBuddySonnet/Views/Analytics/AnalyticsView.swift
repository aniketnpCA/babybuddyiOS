import SwiftUI

struct AnalyticsView: View {
    let child: Child

    @State private var viewModel = AnalyticsViewModel()
    @State private var showingGrowthForm = false
    @State private var showingAIChat = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                if viewModel.isLoading && viewModel.recentFeedings.isEmpty {
                    ProgressView("Loading analytics...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // AI Button
                            aiButton

                            // Monthly comparison card
                            if let comparison = viewModel.monthlyComparison {
                                MonthlyComparisonCard(comparison: comparison)
                            }

                            // Growth charts (WHO comparison)
                            GrowthChart(
                                weightMeasurements: viewModel.weightMeasurements,
                                heightMeasurements: viewModel.heightMeasurements,
                                headCircumferenceMeasurements: viewModel.headCircumferenceMeasurements,
                                birthDate: child.birthDate
                            )

                            // Daily trend (feeding + pumping)
                            DailyTrendChart(
                                dailyFeedingOz: viewModel.dailyFeedingOz,
                                dailyPumpingOz: viewModel.dailyPumpingOz
                            )

                            // Feeding time-of-day
                            FeedingHeatmapChart(
                                feedingByHour: viewModel.feedingByHour
                            )

                            // Sleep patterns
                            SleepPatternChart(
                                sleepBlocks: viewModel.sleepBlocks
                            )

                            // Diaper frequency
                            DiaperFrequencyChart(
                                dailyDiaperCounts: viewModel.dailyDiaperCounts
                            )
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.loadAll(childID: child.id, birthDate: child.birthDate)
                    }
                }

                // FAB for logging growth
                FloatingActionButton(color: .teal) {
                    showingGrowthForm = true
                }
            }
            .navigationTitle("Analytics")
            .task {
                await viewModel.loadAll(childID: child.id, birthDate: child.birthDate)
            }
            .sheet(isPresented: $showingGrowthForm) {
                GrowthFormSheet(
                    childID: child.id,
                    viewModel: viewModel,
                    onSave: {
                        Task {
                            await viewModel.loadAll(childID: child.id, birthDate: child.birthDate)
                        }
                    }
                )
            }
            .sheet(isPresented: $showingAIChat) {
                AIChatSheet(
                    viewModel: viewModel,
                    childAge: child.age,
                    childID: child.id
                )
            }
        }
    }

    private var aiButton: some View {
        Button {
            showingAIChat = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.body.bold())
                Text("Ask AI")
                    .font(.subheadline.bold())
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
