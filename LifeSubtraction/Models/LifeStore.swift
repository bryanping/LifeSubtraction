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

    /// App Group 共享，讓 Widget / Watch 也讀得到。
    private let defaults: UserDefaults = .shared

    init() {
        let savedBirthday = defaults.object(forKey: AppConstants.Key.birthday) as? Date
            ?? Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        self.birthday = savedBirthday

        let savedLife = defaults.integer(forKey: AppConstants.Key.lifeExpectancy)
        self.lifeExpectancy = savedLife.nonZero ?? 80
        self.hasCompletedOnboarding = defaults.bool(forKey: AppConstants.Key.onboarded)

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
    var ageYears: Int { metrics.ageYears }
    var weeksLived: Int { metrics.weeksLived }
    var weeksRemaining: Int { metrics.weeksRemaining }
    var totalWeeks: Int { metrics.totalWeeks }
    var yearsRemaining: Double { Double(metrics.daysRemaining) / 365.25 }

    var newYearsLeft: Int { metrics.newYearsLeft }
    var summersLeft: Int { metrics.summersLeft }
    var tripsLeft: Int { metrics.tripsLeft }
    var parentVisitsLeft: Int { metrics.parentVisitsLeft }
    var booksLeft: Int { metrics.booksLeft }

    // MARK: - Persistence

    private func save() {
        defaults.set(birthday, forKey: AppConstants.Key.birthday)
        defaults.set(lifeExpectancy, forKey: AppConstants.Key.lifeExpectancy)
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
