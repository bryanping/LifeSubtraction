import SwiftUI

struct LifeGoalsView: View {
    @State private var activeGoals: [LifeGoal] = []
    @State private var moments: [LifeMoment] = []
    @State private var tasks: [LifeTask] = []
    @State private var showingCatalog = false
    @State private var showingAddCustom = false
    @State private var navigationPath = NavigationPath()
    // 修改内容 — 規劃頁新增年/月/日切換，依有空時間安排事件
    @State private var planningScope: PlanningScope = .day

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroIntro

                    scopePicker

                    planningScopeContent

                    momentsSection

                    if activeGoals.isEmpty && moments.isEmpty {
                        emptyPrompt
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 2)
            }
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("規劃")
            .navigationBarTitleDisplayMode(.inline)
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

    // 修改内容 — 年/月/日分段切換
    var scopePicker: some View {
        Picker("", selection: $planningScope) {
            ForEach(PlanningScope.allCases) { scope in
                Text(scope.title).tag(scope)
            }
        }
        .pickerStyle(.segmented)
    }

    // 修改内容 — 依切換單位顯示對應的規劃內容
    @ViewBuilder
    var planningScopeContent: some View {
        switch planningScope {
        case .day:
            PlanningDayView(
                goals: activeGoals,
                tasks: tasks,
                onSelectGoal: { navigationPath.append($0) },
                onAcceptSuggestion: { acceptSuggestion($0) }
            )
        case .month:
            PlanningMonthView(
                goals: activeGoals,
                tasks: tasks,
                onSelectGoal: { navigationPath.append($0) }
            )
        case .year:
            PlanningYearView(
                goals: activeGoals,
                tasks: tasks,
                onSelectGoal: { navigationPath.append($0) }
            )
        }
    }

    var heroIntro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("如果人生有限，你想怎麼安排？")
                .font(.title3.weight(.medium))
                .foregroundStyle(LifeTheme.accent)

        }
    }

    var momentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !moments.isEmpty {
                Text("完成紀錄")
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
        tasks = LocalJSONStore.load(
            [LifeTask].self,
            key: StorageKey.lifeTasks,
            defaultValue: []
        )
    }

    func saveGoals() {
        LocalJSONStore.save(activeGoals, key: StorageKey.lifeGoals)
    }

    func saveMoments() {
        LocalJSONStore.save(moments, key: StorageKey.lifeMoments)
    }

    func saveTasks() {
        LocalJSONStore.save(tasks, key: StorageKey.lifeTasks)
    }

    // 修改内容 — 接受空檔建議：任務排入該時段提醒，目標則進入詳情頁安排下一步
    func acceptSuggestion(_ suggestion: PlanningSuggestion) {
        if let taskId = suggestion.taskId,
           let idx = tasks.firstIndex(where: { $0.id == taskId }) {
            let hour = suggestion.slot.startHour
            tasks[idx].reminderDate = Calendar.current.date(
                bySettingHour: hour, minute: 0, second: 0, of: Date()
            )
            saveTasks()
        } else if let goalId = suggestion.goalId {
            navigationPath.append(goalId)
        }
    }
}

#Preview {
    LifeGoalsView()
}
