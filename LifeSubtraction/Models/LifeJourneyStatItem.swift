import Foundation

/// 「人生累積」項目：問卷 baseline + 真實紀錄。
enum LifeJourneyStatMetricKind: String, Codable, CaseIterable, Identifiable {
    case manual

    var id: String { rawValue }

    var displayName: String { "手動 / 紀錄累積" }

    var hint: String { "由問卷估算過去，並透過紀錄持續累加" }

    var defaultUnit: String { "次" }
}

enum JourneyQuestionTemplate: String, Codable, CaseIterable, Identifiable {
    case reading
    case familyTime
    case travel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reading:    return "閱讀"
        case .familyTime: return "家庭時光"
        case .travel:     return "旅行"
        }
    }

    var iconName: String {
        switch self {
        case .reading:    return "book.fill"
        case .familyTime: return "person.2.fill"
        case .travel:     return "airplane"
        }
    }

    var unit: String {
        switch self {
        case .reading:    return "本"
        case .familyTime: return "次"
        case .travel:     return "次"
        }
    }

    var question: String {
        switch self {
        case .reading:    return "你每月平均讀幾本書？"
        case .familyTime: return "你每月大約見家人幾次？"
        case .travel:     return "你每年大約出國幾次？"
        }
    }

    var frequency: RemainingMomentFrequency {
        switch self {
        case .reading, .familyTime: return .monthly
        case .travel:               return .yearly
        }
    }

    var dependsOn: RemainingMomentDependency {
        switch self {
        case .familyTime: return .parents
        default:          return .selfLife
        }
    }

    func baselineEstimate(ageYears: Int, rate: Double) -> Int {
        switch self {
        case .reading, .familyTime:
            return max(0, Int((rate * Double(max(ageYears, 1) * 12)).rounded()))
        case .travel:
            return max(0, Int((rate * Double(max(ageYears, 1))).rounded()))
        }
    }
}

struct LifeJourneyStatItem: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var iconName: String
    var metricKind: LifeJourneyStatMetricKind
    var unit: String
    var baselineEstimate: Int
    var timesPerMonth: Double?
    var timesPerYear: Double?
    var linkedMomentId: UUID?
    var template: JourneyQuestionTemplate?
    var createdAt: Date
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        title: String,
        iconName: String,
        metricKind: LifeJourneyStatMetricKind = .manual,
        unit: String? = nil,
        baselineEstimate: Int = 0,
        timesPerMonth: Double? = nil,
        timesPerYear: Double? = nil,
        linkedMomentId: UUID? = nil,
        template: JourneyQuestionTemplate? = nil,
        createdAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.metricKind = metricKind
        self.unit = unit ?? metricKind.defaultUnit
        self.baselineEstimate = baselineEstimate
        self.timesPerMonth = timesPerMonth
        self.timesPerYear = timesPerYear
        self.linkedMomentId = linkedMomentId
        self.template = template
        self.createdAt = createdAt
        self.isArchived = isArchived
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try c.decode(String.self, forKey: .title)
        iconName = try c.decode(String.self, forKey: .iconName)
        metricKind = try c.decodeIfPresent(LifeJourneyStatMetricKind.self, forKey: .metricKind) ?? .manual
        unit = try c.decodeIfPresent(String.self, forKey: .unit) ?? metricKind.defaultUnit
        baselineEstimate = try c.decodeIfPresent(Int.self, forKey: .baselineEstimate) ?? 0
        timesPerMonth = try c.decodeIfPresent(Double.self, forKey: .timesPerMonth)
        timesPerYear = try c.decodeIfPresent(Double.self, forKey: .timesPerYear)
        linkedMomentId = try c.decodeIfPresent(UUID.self, forKey: .linkedMomentId)
        template = try c.decodeIfPresent(JourneyQuestionTemplate.self, forKey: .template)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        isArchived = try c.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
    }

    enum CodingKeys: String, CodingKey {
        case id, title, iconName, metricKind, unit, baselineEstimate
        case timesPerMonth, timesPerYear, linkedMomentId, template, createdAt, isArchived
    }
}

extension LifeJourneyStatItem {
    static let templateDefaults: [LifeJourneyStatItem] = JourneyQuestionTemplate.allCases.map {
        LifeJourneyStatItem(
            title: $0.title,
            iconName: $0.iconName,
            unit: $0.unit,
            template: $0
        )
    }

    static func isTitleAvailable(_ title: String, among items: [LifeJourneyStatItem]) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return !items.contains { !$0.isArchived && $0.title == trimmed }
    }
}

enum JourneyStatsBootstrap {
    static let questionnaireDoneKey = "journey-questionnaire-done"

    static var isQuestionnaireDone: Bool {
        UserDefaults.shared.bool(forKey: questionnaireDoneKey)
    }

    static func markQuestionnaireDone() {
        UserDefaults.shared.set(true, forKey: questionnaireDoneKey)
    }

    @discardableResult
    static func applyQuestionnaire(
        rates: [JourneyQuestionTemplate: Double],
        ageYears: Int
    ) -> (stats: [LifeJourneyStatItem], moments: [RemainingMomentItem]) {
        var stats: [LifeJourneyStatItem] = []
        var moments: [RemainingMomentItem] = []

        for template in JourneyQuestionTemplate.allCases {
            let rate = rates[template] ?? 0
            let moment = RemainingMomentItem(
                title: template.title,
                iconName: template.iconName,
                unit: template.unit,
                frequency: template.frequency,
                dependsOn: template.dependsOn
            )
            let stat = LifeJourneyStatItem(
                title: template.title,
                iconName: template.iconName,
                unit: template.unit,
                baselineEstimate: template.baselineEstimate(ageYears: ageYears, rate: rate),
                timesPerMonth: template.frequency == .monthly ? rate : nil,
                timesPerYear: template.frequency == .yearly ? rate : nil,
                linkedMomentId: moment.id,
                template: template
            )
            stats.append(stat)
            moments.append(moment)
        }

        markQuestionnaireDone()
        return (stats, moments)
    }

    static func appendJourneyRecord(
        for moment: RemainingMomentItem,
        note: String = "",
        stats: inout [LifeJourneyStatItem],
        records: inout [LifeJourneyStatRecord]
    ) {
        guard let stat = stats.first(where: { $0.linkedMomentId == moment.id && !$0.isArchived }) else {
            return
        }
        records.append(
            LifeJourneyStatRecord(statItemId: stat.id, date: Date(), note: note)
        )
    }
}
