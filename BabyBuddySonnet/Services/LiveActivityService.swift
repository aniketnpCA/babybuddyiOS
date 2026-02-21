import ActivityKit
import Foundation

@Observable
@MainActor
final class LiveActivityService {
    static let shared = LiveActivityService()

    private var currentActivity: Activity<BabyActivityAttributes>?

    var isRunning: Bool {
        currentActivity != nil
    }

    // MARK: - Start

    func startActivity(childName: String, state: BabyActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // End any existing activity first
        endActivity()

        let attributes = BabyActivityAttributes(childName: childName)
        let content = ActivityContent(state: state, staleDate: nil)

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    // MARK: - Update

    func updateActivity(state: BabyActivityAttributes.ContentState) {
        guard let activity = currentActivity else { return }

        Task {
            let content = ActivityContent(state: state, staleDate: nil)
            await activity.update(content)
        }
    }

    // MARK: - End

    func endActivity() {
        guard let activity = currentActivity else { return }

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }

    // MARK: - Convenience

    func updateFromDashboard(
        childName: String,
        nextFeedingTime: Date?,
        nextPumpingTime: Date?,
        nextDiaperTime: Date?,
        dailyConsumedOz: Double,
        dailyTargetOz: Double
    ) {
        let hasTimers = nextFeedingTime != nil || nextPumpingTime != nil || nextDiaperTime != nil
        guard hasTimers else {
            endActivity()
            return
        }

        let state = BabyActivityAttributes.ContentState(
            nextFeedingTime: nextFeedingTime,
            nextPumpingTime: nextPumpingTime,
            nextDiaperTime: nextDiaperTime,
            dailyConsumedOz: dailyConsumedOz,
            dailyTargetOz: dailyTargetOz
        )

        if isRunning {
            updateActivity(state: state)
        } else {
            startActivity(childName: childName, state: state)
        }
    }
}
