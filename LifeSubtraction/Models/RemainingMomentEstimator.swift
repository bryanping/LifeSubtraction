import Foundation

extension RemainingMomentItem {
    /// 向前估算：在剩餘人生窗口內，這件事大約還能發生幾次。
    func estimatedRemainingOccurrences(store: LifeStore, metrics: LifeMetrics) -> Int {
        if title.contains("夏天"), frequency == .yearly {
            return metrics.summersLeft
        }
        if title.contains("新年"), frequency == .yearly {
            return metrics.newYearsLeft
        }

        let windowYears: Int
        switch dependsOn {
        case .selfLife:
            windowYears = metrics.yearsRemaining
        case .parents:
            windowYears = store.parentYearsRemaining
        }

        return max(0, windowYears * estimatedTimesPerYear())
    }
}
