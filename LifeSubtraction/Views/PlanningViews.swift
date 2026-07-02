import SwiftUI

// MARK: - PlanningRecommendationRow
// 年 / 月視圖共用：剩餘時間建議列（暖色虛線，與已排定事件區分開）。不顯示月份／日期文字，點擊導到目標詳情頁選時間。

struct PlanningRecommendationRow: View {
    let recommendation: PlanningRecommendation
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: recommendation.category.iconName)
                    .font(.caption)
                    .foregroundStyle(LifeTheme.warm)

                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.title)
                        .font(.subheadline)
                        .foregroundStyle(LifeTheme.textPrimary)
                        .lineLimit(1)
                    Text(recommendation.subtitle)
                        .font(.caption2)
                        .foregroundStyle(LifeTheme.textTertiary)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LifeTheme.warmSoft)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(LifeTheme.warm.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PlanningTimelineRow
// 日視圖時間軸的單一列：可能是已排定的事件，也可能是空檔建議。

private enum PlanningTimelineRow: Identifiable {
    case event(PlanningItem)
    case suggestion(PlanningSuggestion)

    var id: String {
        switch self {
        case .event(let item): return "event-\(item.id)"
        case .suggestion(let s): return "suggestion-\(s.id)"
        }
    }

    var sortHour: Int {
        switch self {
        case .event(let item): return Calendar.current.component(.hour, from: item.date)
        case .suggestion(let s): return s.slot.startHour
        }
    }
}

// MARK: - PlanningDayView
// 日視圖：時間軸 + 已排定事件 + 空檔建議。

struct PlanningDayView: View {
    let goals: [LifeGoal]
    let tasks: [LifeTask]
    var onSelectGoal: (UUID) -> Void
    var onAcceptSuggestion: (PlanningSuggestion) -> Void

    private var items: [PlanningItem] {
        PlanningEngine.items(scope: .day, anchorDate: Date(), goals: goals, tasks: tasks)
    }

    private var freeSlots: [FreeSlot] {
        PlanningEngine.freeSlots(goals: goals)
    }

    private var suggestions: [PlanningSuggestion] {
        PlanningEngine.suggestions(for: freeSlots, tasks: tasks)
    }

    private var rows: [PlanningTimelineRow] {
        (items.map(PlanningTimelineRow.event) + suggestions.map(PlanningTimelineRow.suggestion))
            .sorted { $0.sortHour < $1.sortHour }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今天的空檔")
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)
                Spacer()
                Text("\(freeSlots.reduce(0) { $0 + $1.durationHours }) 小時可運用")
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textTertiary)
            }

            if rows.isEmpty {
                emptyState
            } else {
                VStack(spacing: 8) {
                    ForEach(rows) { row in
                        rowView(row)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func rowView(_ row: PlanningTimelineRow) -> some View {
        switch row {
        case .event(let item):
            eventRow(item)
        case .suggestion(let suggestion):
            suggestionRow(suggestion)
        }
    }

    private func eventRow(_ item: PlanningItem) -> some View {
        Button {
            if let goalId = item.goalId { onSelectGoal(goalId) }
        } label: {
            HStack(spacing: 12) {
                Text(item.timeLabel)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(LifeTheme.textSecondary)
                    .frame(width: 92, alignment: .leading)

                Image(systemName: item.category.iconName)
                    .font(.caption)
                    .foregroundStyle(LifeTheme.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.subheadline)
                        .foregroundStyle(LifeTheme.textPrimary)
                        .lineLimit(1)
                    Text(item.subtitle)
                        .font(.caption2)
                        .foregroundStyle(LifeTheme.textTertiary)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LifeTheme.glassFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func suggestionRow(_ suggestion: PlanningSuggestion) -> some View {
        HStack(spacing: 12) {
            Text(suggestion.slot.label)
                .font(.caption.monospacedDigit())
                .foregroundStyle(LifeTheme.warm)
                .frame(width: 92, alignment: .leading)

            Image(systemName: suggestion.category.iconName)
                .font(.caption)
                .foregroundStyle(LifeTheme.warm)

            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.title)
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textPrimary)
                    .lineLimit(1)
                Text(suggestion.subtitle)
                    .font(.caption2)
                    .foregroundStyle(LifeTheme.textTertiary)
            }

            Spacer()

            Button {
                onAcceptSuggestion(suggestion)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(LifeTheme.warm)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LifeTheme.warmSoft)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(LifeTheme.warm.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        )
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 30))
                .foregroundStyle(LifeTheme.accent.opacity(0.7))
            Text("今天還沒有排定的事")
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle(padding: 20)
    }
}

// MARK: - PlanningMonthView
// 月視圖：依日期分組列出本月的到期目標 / 任務提醒，並依剩餘天數建議每日可推進的內容。

struct PlanningMonthView: View {
    let goals: [LifeGoal]
    let tasks: [LifeTask]
    var onSelectGoal: (UUID) -> Void

    private var items: [PlanningItem] {
        PlanningEngine.items(scope: .month, anchorDate: Date(), goals: goals, tasks: tasks)
    }

    private var groupedByDay: [(day: Int, items: [PlanningItem])] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: items) { cal.component(.day, from: $0.date) }
        return grouped.keys.sorted().map { day in (day: day, items: grouped[day] ?? []) }
    }

    private var recommendations: [PlanningRecommendation] {
        let cal = Calendar.current
        let occupiedDays = Set(items.map { cal.component(.day, from: $0.date) })
        return PlanningEngine.dailyRecommendations(
            anchorDate: Date(),
            goals: goals,
            tasks: tasks,
            occupiedDays: occupiedDays
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("本月安排")
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)

                if groupedByDay.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 8) {
                        ForEach(groupedByDay, id: \.day) { entry in
                            dayGroupRow(day: entry.day, items: entry.items)
                        }
                    }
                }
            }

            if !recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("剩餘天數建議")
                        .font(.headline)
                        .foregroundStyle(LifeTheme.textPrimary)

                    VStack(spacing: 8) {
                        ForEach(recommendations) { rec in
                            PlanningRecommendationRow(recommendation: rec) {
                                if let goalId = rec.goalId { onSelectGoal(goalId) }
                            }
                        }
                    }
                }
            }
        }
    }

    private func dayGroupRow(day: Int, items: [PlanningItem]) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(day)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(LifeTheme.accent)
                .frame(width: 32, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(items) { item in
                    Button {
                        if let goalId = item.goalId { onSelectGoal(goalId) }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: item.category.iconName)
                                .font(.caption2)
                                .foregroundStyle(LifeTheme.accent)
                            Text(item.title)
                                .font(.subheadline)
                                .foregroundStyle(LifeTheme.textPrimary)
                                .lineLimit(1)
                            Spacer()
                            Text(item.timeLabel)
                                .font(.caption2)
                                .foregroundStyle(LifeTheme.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LifeTheme.glassFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.system(size: 30))
                .foregroundStyle(LifeTheme.accent.opacity(0.7))
            Text("這個月還沒有到期或提醒的事")
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle(padding: 20)
    }
}

// MARK: - PlanningYearView
// 年視圖：本年度目標時間軸，並依剩餘月數建議每月可聚焦的內容。

struct PlanningYearView: View {
    let goals: [LifeGoal]
    let tasks: [LifeTask]
    var onSelectGoal: (UUID) -> Void

    private var items: [PlanningItem] {
        PlanningEngine.items(scope: .year, anchorDate: Date(), goals: goals, tasks: tasks)
    }

    private var recommendations: [PlanningRecommendation] {
        let cal = Calendar.current
        let occupiedMonths = Set(items.map { cal.component(.month, from: $0.date) })
        return PlanningEngine.monthlyRecommendations(
            anchorDate: Date(),
            goals: goals,
            tasks: tasks,
            occupiedMonths: occupiedMonths
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("今年的目標時間軸")
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)

                if items.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 8) {
                        ForEach(items) { item in
                            yearItemRow(item)
                        }
                    }
                }
            }

            if !recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("剩餘月份建議")
                        .font(.headline)
                        .foregroundStyle(LifeTheme.textPrimary)

                    VStack(spacing: 8) {
                        ForEach(recommendations) { rec in
                            PlanningRecommendationRow(recommendation: rec) {
                                if let goalId = rec.goalId { onSelectGoal(goalId) }
                            }
                        }
                    }
                }
            }
        }
    }

    private func yearItemRow(_ item: PlanningItem) -> some View {
        Button {
            if let goalId = item.goalId { onSelectGoal(goalId) }
        } label: {
            HStack(spacing: 12) {
                Text(monthDayLabel(for: item.date))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(LifeTheme.textSecondary)
                    .frame(width: 56, alignment: .leading)

                Image(systemName: item.category.iconName)
                    .font(.caption)
                    .foregroundStyle(LifeTheme.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.subheadline)
                        .foregroundStyle(LifeTheme.textPrimary)
                        .lineLimit(1)
                    Text(item.subtitle)
                        .font(.caption2)
                        .foregroundStyle(LifeTheme.textTertiary)
                }

                Spacer()

                Text(item.timeLabel)
                    .font(.caption2)
                    .foregroundStyle(LifeTheme.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LifeTheme.glassFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func monthDayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "star.circle")
                .font(.system(size: 30))
                .foregroundStyle(LifeTheme.accent.opacity(0.7))
            Text("今年還沒有設定到期日的目標")
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle(padding: 20)
    }
}
