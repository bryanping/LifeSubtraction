import Foundation

/// 一次性資料遷移：舊 key 改名、parentAge → FamilyMember、清除已廢棄資料。
enum MigrationManager {
    private static let migrationVersionKey = "data-migration-version"
    private static let currentVersion = 2

    static func runIfNeeded() {
        let defaults = UserDefaults.shared
        let version = defaults.integer(forKey: migrationVersionKey)
        guard version < currentVersion else { return }

        if version < 1 {
            migrateStorageKeys()
            migrateParentAgeToFamilyMember()
            removeDeprecatedData()
        }
        if version < 2 {
            migrateLegacyValueReflections()
        }

        defaults.set(currentVersion, forKey: migrationVersionKey)
    }

    private static func migrateStorageKeys() {
        let defaults = UserDefaults.shared
        let renames: [(old: String, new: String)] = [
            (StorageKey.legacyPersonalEventItems, StorageKey.personalEventItems),
            (StorageKey.legacyPersonalEventRecords, StorageKey.personalEventRecords),
        ]
        for pair in renames {
            if defaults.data(forKey: pair.new) == nil,
               let data = defaults.data(forKey: pair.old) {
                defaults.set(data, forKey: pair.new)
                defaults.removeObject(forKey: pair.old)
            }
        }
    }

    private static func migrateParentAgeToFamilyMember() {
        let existing = LocalJSONStore.load(
            [FamilyMember].self,
            key: StorageKey.familyMembers,
            defaultValue: []
        )
        guard existing.isEmpty else { return }

        let defaults = UserDefaults.shared
        let parentAge = defaults.integer(forKey: StorageKey.legacyParentAge).nonZero ?? 60
        let parentLife = defaults.integer(forKey: StorageKey.legacyParentLifeExpectancy).nonZero ?? 80

        let member = FamilyMember(
            name: "父母",
            relation: .parent,
            currentAge: parentAge,
            lifeExpectancy: parentLife,
            note: "由舊版父母年齡設定自動遷移",
            createdAt: Date(),
            isArchived: false
        )
        LocalJSONStore.save([member], key: StorageKey.familyMembers)

        defaults.removeObject(forKey: StorageKey.legacyParentAge)
        defaults.removeObject(forKey: StorageKey.legacyParentLifeExpectancy)
    }

    private static func removeDeprecatedData() {
        LocalJSONStore.remove(key: StorageKey.legacyLifeGoals)
    }

    /// 舊版 LifeValue.reflection 欄位 → 一般反思紀錄。
    /// 目前專案中的 ReflectionEntry 沒有 tag / valueId，因此僅保留文字內容。
    private static func migrateLegacyValueReflections() {
        struct LegacyLifeValue: Codable {
            var id: UUID
            var name: String
            var icon: String
            var reflection: String?
        }

        let values = LocalJSONStore.load(
            [LegacyLifeValue].self,
            key: StorageKey.lifeValues,
            defaultValue: []
        )
        guard values.contains(where: { !($0.reflection ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            return
        }

        var entries = LocalJSONStore.load(
            [ReflectionEntry].self,
            key: StorageKey.reflectionEntries,
            defaultValue: []
        )
        var changed = false

        for value in values {
            let text = (value.reflection ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            if entries.contains(where: { $0.text == text }) { continue }
            entries.append(ReflectionEntry(
                date: Date(),
                text: text,
                period: .daily
            ))
            changed = true
        }

        if changed {
            LocalJSONStore.save(entries, key: StorageKey.reflectionEntries)
        }

        let cleaned = values.map {
            LifeValue(id: $0.id, name: $0.name, icon: $0.icon)
        }
        LocalJSONStore.save(cleaned, key: StorageKey.lifeValues)
    }

    static func resetAllData() {
        let defaults = UserDefaults.shared
        let keysToRemove = [
            AppConstants.Key.birthday,
            AppConstants.Key.lifeExpectancy,
            AppConstants.Key.onboarded,
            StorageKey.lifeValues,
            StorageKey.reflectionEntries,
            StorageKey.regretItems,
            StorageKey.personalEventItems,
            StorageKey.personalEventRecords,
            StorageKey.lifeJourneyStatItems,
            StorageKey.familyMembers,
            StorageKey.familyMomentRecords,
            StorageKey.legacyPersonalEventItems,
            StorageKey.legacyPersonalEventRecords,
            StorageKey.legacyLifeGoals,
            StorageKey.legacyParentAge,
            StorageKey.legacyParentLifeExpectancy,
            migrationVersionKey,
        ]
        for key in keysToRemove {
            defaults.removeObject(forKey: key)
        }
        defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix("alignment-") }
            .forEach { defaults.removeObject(forKey: $0) }
    }
}
