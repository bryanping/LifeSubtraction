import Foundation
import Combine

/// 價值觀列表，走 JSONStore 持久化。
final class ValueStore: ObservableObject {
    @Published var values: [LifeValue] {
        didSet { save() }
    }

    init() {
        MigrationManager.runIfNeeded()
        self.values = LocalJSONStore.load(
            [LifeValue].self,
            key: StorageKey.lifeValues,
            defaultValue: Self.defaultValues
        )
    }

    private static let defaultValues: [LifeValue] = [
        LifeValue(name: "家人", icon: "house.fill"),
        LifeValue(name: "健康", icon: "heart.fill"),
        LifeValue(name: "成長", icon: "leaf.fill"),
    ]

    private func save() {
        LocalJSONStore.save(values, key: StorageKey.lifeValues)
    }
}
