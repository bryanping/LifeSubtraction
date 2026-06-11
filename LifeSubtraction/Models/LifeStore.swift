import Foundation
import Combine
#if canImport(WidgetKit)
import WidgetKit
#endif

// MARK: - Models

struct LifeValue: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var icon: String
    var reflection: String = ""
}

// MARK: - Store

class LifeStore: ObservableObject {
    @Published var birthday: Date {
        didSet { save(); reloadWidgets() }
    }
    @Published var lifeExpectancy: Int {
        didSet { save(); reloadWidgets() }
    }
    @Published var values: [LifeValue] {
        didSet { save() }
    }
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            defaults.set(hasCompletedOnboarding, forKey: AppConstants.Key.onboarded)
        }
    }

    @Published var parentAge: Int {
        didSet { save() }
    }

    @Published var parentLifeExpectancy: Int {
        didSet { save() }
    }

    private let defaults: UserDefaults = .shared

    init() {
        MigrationManager.runIfNeeded()

        let savedBirthday = defaults.object(forKey: AppConstants.Key.birthday) as? Date
            ?? Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        self.birthday = savedBirthday

        let savedLife = defaults.integer(forKey: AppConstants.Key.lifeExpectancy)
        self.lifeExpectancy = savedLife.nonZero ?? 80
        self.hasCompletedOnboarding = defaults.bool(forKey: AppConstants.Key.onboarded)

        let savedParentAge = defaults.integer(forKey: "parentAge")
        self.parentAge = savedParentAge.nonZero ?? 60

        let savedParentLife = defaults.integer(forKey: "parentLifeExpectancy")
        self.parentLifeExpectancy = savedParentLife.nonZero ?? 80

        if let data = defaults.data(forKey: AppConstants.Key.values),
           let decoded = try? JSONDecoder().decode([LifeValue].self, from: data) {
            self.values = decoded
        } else {
            self.values = [
                LifeValue(name: "家人", icon: "house.fill"),
                LifeValue(name: "健康", icon: "heart.fill"),
                LifeValue(name: "成長", icon: "leaf.fill"),
            ]
        }
    }

    // MARK: - Computed (delegate to LifeMetrics)

    var metrics: LifeMetrics { LifeMetrics(birthday: birthday, lifeExpectancy: lifeExpectancy) }

    var daysLived: Int { metrics.daysLived }
    var totalDays: Int { metrics.totalDays }
    var daysRemaining: Int { metrics.daysRemaining }
    var percentUsed: Double { metrics.percentUsed }
    var percentRemaining: Double { metrics.percentRemaining }
    var ageYears: Int { metrics.ageYears }
    var weeksLived: Int { metrics.weeksLived }
    var weeksRemaining: Int { metrics.weeksRemaining }
    var totalWeeks: Int { metrics.totalWeeks }
    var yearsRemaining: Int { metrics.yearsRemaining }
    var monthsRemaining: Int { Int(metrics.monthsRemainingPrecise.rounded(.down)) }
    var newYearsLeft: Int { metrics.newYearsLeft }
    var summersLeft: Int { metrics.summersLeft }

    var parentYearsRemaining: Int {
        max(0, parentLifeExpectancy - parentAge)
    }

    // MARK: - Persistence

    private func save() {
        defaults.set(birthday, forKey: AppConstants.Key.birthday)
        defaults.set(lifeExpectancy, forKey: AppConstants.Key.lifeExpectancy)
        defaults.set(parentAge, forKey: "parentAge")
        defaults.set(parentLifeExpectancy, forKey: "parentLifeExpectancy")
        if let encoded = try? JSONEncoder().encode(values) {
            defaults.set(encoded, forKey: AppConstants.Key.values)
        }
    }

    private func reloadWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}

extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}
