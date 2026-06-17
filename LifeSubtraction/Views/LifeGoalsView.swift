import SwiftUI

struct LifeGoalsView: View {
    @State private var activeGoals: [LifeGoal] = []
    @State private var moments: [LifeMoment] = []
    @State private var showingCatalog = false
    @State private var showingAddCustom = false
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroIntro

                    if !activeGoals.isEmpty {
                        activeGoalsSection
                    }

                    momentsSection

                    if activeGoals.isEmpty && moments.isEmpty {
                        emptyPrompt
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("人生目標")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { showingCatalog = true } label: {
                            Label("從靈感庫加入", systemImage: "books.vertical")
                        }
                        Button { showingAddCustom = true } label: {
                            Label("自訂人生事件", systemImage: "plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(LifeTheme.accent)
                    }
                }
            }
            .onAppear {
                LifeGoalMigration.migrateIfNeeded()
                loadData()
            }
            .sheet(isPresented: $showingCatalog) {
                GoalCatalogView(goals: activeGoals) { entry in
                    adoptCatalogEntry(entry)
                }
            }
            .sheet(isPresented: $showingAddCustom) {
                GoalSetupView { goal in
                    activeGoals.insert(goal, at: 0)
                    saveGoals()
                    showingAddCustom = false
                    navigationPath.append(GoalRoute(goalId: goal.id, startInEditMode: false))
                }
            }
            .navigationDestination(for: GoalRoute.self) { route in
                LifeGoalDetailView(
                    goals: $activeGoals,
                    moments: $moments,
                    goalId: route.goalId,
                    startInEditMode: route.startInEditMode
                )
            }
            .navigationDestination(for: UUID.self) { goalId in
                LifeGoalDetailView(
                    goals: $activeGoals,
                    moments: $moments,
                    goalId: goalId
                )
            }
        }
    }

    var heroIntro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("如果人生有限，")
                .font(.title3.weight(.medium))
                .foregroundStyle(LifeTheme.textPrimary)
            Text("你最想完成什麼？")
                .font(.title3.weight(.medium))
                .foregroundStyle(LifeTheme.accent)
            Text("一次一件事，完成後成為你的人生回憶。")
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)
                .padding(.top, 4)
        }
    }

    var activeGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("進行中")
                .font(.headline)
                .foregroundStyle(LifeTheme.textPrimary)

            ForEach(activeGoals.filter { $0.status == .active }) { goal in
                NavigationLink(value: goal.id) {
                    goalCard(goal)
                }
                .buttonStyle(.plain)
            }
        }
    }

    var momentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !moments.isEmpty {
                Text("人生時刻")
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)

                ForEach(moments) { moment in
                    momentCard(moment)
                }
            }
        }
    }

    var emptyPrompt: some View {
        VStack(spacing: 14) {
            Image(systemName: "star.circle")
                .font(.system(size: 40))
                .foregroundStyle(LifeTheme.accent.opacity(0.8))
            Text("從靈感庫選一件想完成的事")
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)
            PrimaryButton("探索 100 個人生事件", icon: "sparkles") {
                showingCatalog = true
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle(padding: 24)
    }

    func goalCard(_ goal: LifeGoal) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: goal.category.iconName)
                    .foregroundStyle(LifeTheme.accent)
                Text(goal.category.displayName)
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textTertiary)
                Spacer()
                Text("\(goal.completedStageCount)/\(goal.stages.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(LifeTheme.warm)
            }

            Text(goal.displayTitle)
                .font(.headline)
                .foregroundStyle(LifeTheme.textPrimary)
                .lineLimit(2)

            if let days = goal.daysUntilDue {
                HStack(spacing: 4) {
                    Image(systemName: goal.isOverdue ? "exclamationmark.triangle.fill" : "calendar")
                        .font(.caption2)
                    Text(days < 0 ? "已逾期 \(abs(days)) 天" : (days == 0 ? "今天到期" : "還剩 \(days) 天"))
                        .font(.caption2)
                }
                .foregroundStyle(goal.isOverdue ? Color.red.opacity(0.85) : LifeTheme.textTertiary)
            }

            ProgressBar(
                value: goal.stages.isEmpty ? 0 : Double(goal.completedStageCount) / Double(goal.stages.count),
                color: LifeTheme.accent,
                useGradient: false
            )
            .frame(height: 6)
        }
        .cardStyle(padding: 16)
    }

    func momentCard(_ moment: LifeMoment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: moment.category.iconName)
                    .foregroundStyle(LifeTheme.accent)
                Text(moment.summaryLine)
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textPrimary)
            }
            if !moment.notes.isEmpty {
                Text(moment.notes)
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textSecondary)
            }
            Text("共花費 \(moment.durationDays) 天")
                .font(.caption2)
                .foregroundStyle(LifeTheme.textTertiary)

            ShareLink(item: shareText(for: moment)) {
                Label("分享", systemImage: "square.and.arrow.up")
                    .font(.caption)
                    .foregroundStyle(LifeTheme.accent)
            }
        }
        .cardStyle(padding: 16)
    }

    func adoptCatalogEntry(_ entry: GoalCatalogEntry) {
        let goal = entry.makeGoal()
        GoalCatalogStats.recordAdoption(catalogId: entry.id)
        activeGoals.insert(goal, at: 0)
        saveGoals()
        showingCatalog = false
        DispatchQueue.main.async {
            navigationPath.append(GoalRoute(goalId: goal.id, startInEditMode: true))
        }
    }

    func shareText(for moment: LifeMoment) -> String {
        var lines = ["我完成了：", moment.title]
        if !moment.notes.isEmpty { lines.append(moment.notes) }
        lines.append("共花費 \(moment.durationDays) 天")
        lines.append("— 人生減法")
        return lines.joined(separator: "\n")
    }

    func loadData() {
        activeGoals = LocalJSONStore.load(
            [LifeGoal].self,
            key: StorageKey.lifeGoals,
            defaultValue: []
        )
        moments = LocalJSONStore.load(
            [LifeMoment].self,
            key: StorageKey.lifeMoments,
            defaultValue: []
        )
    }

    func saveGoals() {
        LocalJSONStore.save(activeGoals, key: StorageKey.lifeGoals)
    }

    func saveMoments() {
        LocalJSONStore.save(moments, key: StorageKey.lifeMoments)
    }
}

#Preview {
    LifeGoalsView()
}
