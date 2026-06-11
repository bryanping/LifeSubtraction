import Foundation
import Combine

/// 統一反思持久化層。
/// 目前專案採用簡化版 ReflectionEntry（沒有 tag / valueId），
/// 因此這裡保留新版呼叫介面，但在內部用相容方式降級處理。
final class ReflectionStore: ObservableObject {
    @Published private(set) var entries: [ReflectionEntry] = []

    private let valueNotePrefix = "[value-note]"
    private let watchPrefix = "[watch]"

    init() {
        load()
    }

    func load() {
        entries = LocalJSONStore.load(
            [ReflectionEntry].self,
            key: StorageKey.reflectionEntries,
            defaultValue: []
        )
        if ReflectionEntry.migrateLegacyWeeklyFocus(into: &entries) {
            persist()
        }
    }

    func persist() {
        LocalJSONStore.save(entries, key: StorageKey.reflectionEntries)
    }

    func current(period: ReflectionPeriod, date: Date = Date()) -> ReflectionEntry? {
        ReflectionEntry.current(
            in: journalEntries,
            period: period,
            date: date
        )
    }

    @discardableResult
    func upsertJournal(text: String, period: ReflectionPeriod, date: Date = Date()) -> ReflectionEntry {
        let entry = ReflectionEntry.upsert(
            text: text,
            period: period,
            in: &entries,
            date: date
        )
        persist()
        return entry
    }

    func valueNote(for valueId: UUID) -> String {
        let prefix = "\(valueNotePrefix):\(valueId.uuidString):"
        guard let entry = entries.first(where: { $0.text.hasPrefix(prefix) }) else {
            return ""
        }
        return String(entry.text.dropFirst(prefix.count))
    }

    func upsertValueNote(_ text: String, valueId: UUID) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefix = "\(valueNotePrefix):\(valueId.uuidString):"

        if let index = entries.firstIndex(where: { $0.text.hasPrefix(prefix) }) {
            if trimmed.isEmpty {
                entries.remove(at: index)
            } else {
                entries[index].text = prefix + trimmed
                entries[index].date = Date()
            }
        } else if !trimmed.isEmpty {
            entries.append(ReflectionEntry(
                date: Date(),
                text: prefix + trimmed,
                period: .daily
            ))
        }

        persist()
    }

    @discardableResult
    func upsertWatchReflection(text: String, date: Date = Date()) -> ReflectionEntry {
        let wrapped = "\(watchPrefix):\(text)"
        let entry = ReflectionEntry.upsert(
            text: wrapped,
            period: .daily,
            in: &entries,
            date: date
        )
        persist()
        return entry
    }

    var journalEntries: [ReflectionEntry] {
        entries.filter {
            !$0.text.hasPrefix(valueNotePrefix + ":") &&
            !$0.text.hasPrefix(watchPrefix + ":")
        }
    }

    var countThisYear: Int {
        let year = Calendar.current.component(.year, from: Date())
        return journalEntries.filter {
            Calendar.current.component(.year, from: $0.date) == year
        }.count
    }

    func todayJournalPrompt() -> String {
        if let saved = current(period: .daily) {
            return saved.text
        }
        return ReflectionPeriod.daily.prompt
    }
}
