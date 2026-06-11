import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct AppBackupSnapshot: Codable {
    struct Profile: Codable {
        var birthday: Date
        var lifeExpectancy: Int
        var hasCompletedOnboarding: Bool
    }

    var schemaVersion: Int
    var exportedAt: Date
    var profile: Profile
    var values: [LifeValue]
    var reflections: [ReflectionEntry]
    var regretItems: [RegretAvoidanceItem]
    var lifeJourneyStatItems: [LifeJourneyStatItem]
    var remainingMomentItems: [RemainingMomentItem]
    var remainingMomentRecords: [RemainingMomentRecord]
    var familyMembers: [FamilyMember]
    var familyMomentRecords: [FamilyMomentRecord]
    var alignments: [String: LifeAlignmentRecord]
    var weeklyFocuses: [String: String]

    static func capture(defaults: UserDefaults = .shared) -> AppBackupSnapshot {
        let dictionary = defaults.dictionaryRepresentation()
        let alignmentKeys = dictionary.keys.filter { $0.hasPrefix("alignment-") }
        let weeklyFocusKeys = dictionary.keys.filter { $0.hasPrefix("weekly-focus-") }

        var alignments: [String: LifeAlignmentRecord] = [:]
        for key in alignmentKeys {
            if let record = LocalJSONStore.loadOptional(LifeAlignmentRecord.self, key: key) {
                alignments[key] = record
            }
        }

        var weeklyFocuses: [String: String] = [:]
        for key in weeklyFocusKeys {
            if let text = LocalJSONStore.loadOptional(String.self, key: key),
               !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                weeklyFocuses[key] = text
            }
        }

        return AppBackupSnapshot(
            schemaVersion: 1,
            exportedAt: Date(),
            profile: Profile(
                birthday: defaults.object(forKey: AppConstants.Key.birthday) as? Date ?? Date(),
                lifeExpectancy: defaults.integer(forKey: AppConstants.Key.lifeExpectancy).nonZero ?? 80,
                hasCompletedOnboarding: defaults.bool(forKey: AppConstants.Key.onboarded)
            ),
            values: LocalJSONStore.load([LifeValue].self, key: StorageKey.lifeValues, defaultValue: []),
            reflections: LocalJSONStore.load([ReflectionEntry].self, key: StorageKey.reflectionEntries, defaultValue: []),
            regretItems: LocalJSONStore.load([RegretAvoidanceItem].self, key: StorageKey.regretItems, defaultValue: []),
            lifeJourneyStatItems: LocalJSONStore.load([LifeJourneyStatItem].self, key: StorageKey.lifeJourneyStatItems, defaultValue: []),
            remainingMomentItems: LocalJSONStore.load([RemainingMomentItem].self, key: StorageKey.personalEventItems, defaultValue: []),
            remainingMomentRecords: LocalJSONStore.load([RemainingMomentRecord].self, key: StorageKey.personalEventRecords, defaultValue: []),
            familyMembers: LocalJSONStore.load([FamilyMember].self, key: StorageKey.familyMembers, defaultValue: []),
            familyMomentRecords: LocalJSONStore.load([FamilyMomentRecord].self, key: StorageKey.familyMomentRecords, defaultValue: []),
            alignments: alignments,
            weeklyFocuses: weeklyFocuses
        )
    }
}

struct BackupDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]
    static let defaultFilenamePrefix = "LifeSubtraction-Backup"

    let data: Data

    init(snapshot: AppBackupSnapshot) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.data = try encoder.encode(snapshot)
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }

    static var defaultFilename: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmm"
        return "\(defaultFilenamePrefix)-\(formatter.string(from: Date())).json"
    }
}
