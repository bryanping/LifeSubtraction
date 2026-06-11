import ActivityKit
import Foundation

/// 與 Widget Extension 中 `LifeSubtractionWidgetAttributes` 結構一致（跨 target 需手動同步）。
struct LifeSubtractionWidgetAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var daysRemaining: Int
        var percentUsed: Double
    }

    var goalLabel: String
}

/// 綁定個人生命倒數的 Live Activity（鎖定畫面 / 動態島）。
@MainActor
enum LiveActivityManager {
    private static var currentActivity: Activity<LifeSubtractionWidgetAttributes>?

    static func sync(with store: LifeStore) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let metrics = store.metrics
        let state = LifeSubtractionWidgetAttributes.ContentState(
            daysRemaining: metrics.daysRemaining,
            percentUsed: metrics.percentUsed
        )
        let attributes = LifeSubtractionWidgetAttributes(goalLabel: "人生剩餘")

        if let activity = currentActivity {
            Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
            return
        }

        if let existing = Activity<LifeSubtractionWidgetAttributes>.activities.first {
            currentActivity = existing
            Task { await existing.update(ActivityContent(state: state, staleDate: nil)) }
            return
        }

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
        } catch {
            // 使用者未授權或裝置不支援時靜默略過
        }
    }

    static func endAll() {
        Task {
            for activity in Activity<LifeSubtractionWidgetAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            currentActivity = nil
        }
    }
}
