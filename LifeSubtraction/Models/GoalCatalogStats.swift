import Foundation

/// 靈感庫項目的完成次數與全球添加次數（本地累計 + 種子基線，未來可同步伺服器）。
enum GoalCatalogStats {
    enum SortMode: String, CaseIterable, Identifiable {
        case popular = "熱門"
        case defaultOrder = "預設"
        case myCompletions = "我完成最多"

        var id: String { rawValue }
    }

    // MARK: - Global adoption

    static func recordAdoption(catalogId: String) {
        var counts = localAdoptionCounts
        counts[catalogId, default: 0] += 1
        localAdoptionCounts = counts
    }

    static func globalAdoptionCount(catalogId: String) -> Int {
        seededBaseline(catalogId) + (localAdoptionCounts[catalogId] ?? 0)
    }

    // MARK: - User completions

    static func userCompletedCount(catalogId: String, goals: [LifeGoal]) -> Int {
        goals.filter { $0.catalogId == catalogId && $0.status == .completed }.count
    }

    // MARK: - Sort

    static func sorted(
        _ entries: [GoalCatalogEntry],
        mode: SortMode,
        goals: [LifeGoal]
    ) -> [GoalCatalogEntry] {
        switch mode {
        case .defaultOrder:
            return entries
        case .popular:
            return entries.sorted {
                globalAdoptionCount(catalogId: $0.id) > globalAdoptionCount(catalogId: $1.id)
            }
        case .myCompletions:
            return entries.sorted {
                let left = userCompletedCount(catalogId: $0.id, goals: goals)
                let right = userCompletedCount(catalogId: $1.id, goals: goals)
                if left != right { return left > right }
                return globalAdoptionCount(catalogId: $0.id) > globalAdoptionCount(catalogId: $1.id)
            }
        }
    }

    // MARK: - Private

    private static var localAdoptionCounts: [String: Int] {
        get {
            LocalJSONStore.load([String: Int].self, key: StorageKey.goalCatalogAdoptionCounts, defaultValue: [:])
        }
        set {
            LocalJSONStore.save(newValue, key: StorageKey.goalCatalogAdoptionCounts)
        }
    }

    /// 穩定種子基線，模擬全球累計；日後由伺服器覆寫。
    private static func seededBaseline(_ catalogId: String) -> Int {
        let hash = catalogId.unicodeScalars.reduce(5381) { ($0 << 5) &+ $0 &+ Int($1.value) }
        return 120 + abs(hash % 4800)
    }
}
