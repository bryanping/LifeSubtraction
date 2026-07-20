import SwiftUI

struct GoalRoute: Hashable {
    let goalId: UUID
    let startInEditMode: Bool
}

struct LifeGoalDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var goals: [LifeGoal]
    @Binding var moments: [LifeMoment]
    let goalId: UUID
    var startInEditMode: Bool = false

    @State private var showCompletionSheet = false
    @State private var showDeleteConfirm = false
    @State private var remindersEnabled = false
    @State private var calendarSyncEnabled = false
    @State private var isEditingStages = false
    @State private var checkInMinutes = 60      // 修改内容 — 打卡輸入
    @State private var checkInNote = ""         // 修改内容 — 打卡輸入
    @State private var checkInStageId: UUID?    // 修改内容 — 目前展開打卡輸入的步驟

    private var goalIndex: Int? {
        goals.firstIndex { $0.id == goalId }
    }

    var body: some View {
        Group {
            if let index = goalIndex {
                content(for: index)
            } else {
                Text("找不到目標")
                    .foregroundStyle(LifeTheme.textSecondary)
            }
        }
        .background(LifeTheme.subtleBackground.ignoresSafeArea())
        .navigationTitle(goals.first(where: { $0.id == goalId })?.displayTitle ?? "規劃")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if goals.first(where: { $0.id == goalId })?.status == .active {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            withAnimation(.snappy) { isEditingStages.toggle() }
                        } label: {
                            Label(isEditingStages ? "完成編輯步驟" : "編輯步驟", systemImage: "list.bullet")
                        }
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("刪除目標", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(LifeTheme.accent)
                    }
                }
            }
        }
        .confirmationDialog(
            "確定刪除此進行中的目標？",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("刪除", role: .destructive) {
                deleteGoal()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("刪除後無法復原，相關提醒也會一併移除。")
        }
        .onAppear {
            if startInEditMode {
                isEditingStages = true
            }
        }
        .sheet(isPresented: $showCompletionSheet) {
            if let completed = goals.first(where: { $0.id == goalId && $0.status == .completed }) {
                GoalCompletionSheet(
                    goal: completed,
                    onAddSuggestion: { title, category in
                        addSuggestedGoal(title: title, category: category)
                        showCompletionSheet = false
                    },
                    onDismiss: { showCompletionSheet = false }
                )
            }
        }
    }

    @ViewBuilder
    private func content(for index: Int) -> some View {
        let goal = goals[index]

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                detailConfigurator(index: index, goal: goal)
                stagesSection(index: index, goal: goal)

                if goal.status == .active {
                    timePlanningSection(index: index, goal: goal)

                    GoalDueDateSection(
                        dueDate: $goals[index].dueDate,
                        originalDueDate: $goals[index].originalDueDate,
                        extensionCount: $goals[index].extensionCount,
                        isEditable: true,
                        onUpdate: saveGoals
                    )
                }

                notesSection(index: index)

                if goal.status == .active {
                    remindersToggle(index: index, goal: goal)

                    if goal.allStagesDone {
                        PrimaryButton("標記完成", icon: "checkmark.seal.fill") {
                            completeGoal(at: index)
                        }
                    }
                }

                if goal.status == .completed {
                    completedSummary(goal)
                    ShareLink(item: goal.shareText()) {
                        Label("分享這次完成", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundStyle(LifeTheme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
            }
            .padding()
        }
    }

    func detailConfigurator(index: Int, goal: LifeGoal) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            GoalDetailConfiguratorView(
                catalogId: goal.catalogId,
                selections: $goals[index].detailSelections,
                isEditable: goal.status == .active
            ) {
                saveGoals()
            }

            if goal.status == .completed {
                Label("已完成", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 4)
            }
        }
    }

    func stagesSection(index: Int, goal: LifeGoal) -> some View {
        Group {
            if isEditingStages && goal.status == .active {
                GoalStagesEditor(stages: $goals[index].stages) {
                    saveGoals()
                }
                .cardStyle()
            } else {
                // 修改内容 — 進度與執行紀錄整合：每個步驟可展開打卡（分鐘＋一句話），紀錄掛在步驟下
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("進度")
                            .font(.headline)
                            .foregroundStyle(LifeTheme.textPrimary)
                        Spacer()
                        if goal.status == .active {
                            Text(String(format: "本週 %.1f / %.1f 小時", Double(goal.minutesThisWeek) / 60, goal.effectiveWeeklyHours))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(LifeTheme.accent)
                        }
                    }

                    if let progress = goal.timeProgress {
                        VStack(alignment: .leading, spacing: 6) {
                            ProgressView(value: progress)
                                .tint(LifeTheme.accent)
                            Text(String(format: "累積 %.1f / %d 小時", goal.loggedHours, goal.estimatedHours ?? 0))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(LifeTheme.textTertiary)
                        }
                    }

                    ForEach(goal.stages) { stage in
                        stageRow(index: index, goal: goal, stage: stage)
                    }

                    let unassigned = goal.checkIns.filter { $0.stageId == nil }
                    if !unassigned.isEmpty {
                        Text("其他紀錄")
                            .font(.caption)
                            .foregroundStyle(LifeTheme.textTertiary)
                        ForEach(unassigned) { record in
                            checkInRow(record)
                        }
                    }
                }
                .cardStyle()
            }
        }
    }

    // 修改内容 — 單一步驟列：勾選＋打卡按鈕＋該步驟紀錄＋展開輸入
    @ViewBuilder
    func stageRow(index: Int, goal: LifeGoal, stage: GoalStage) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Button {
                    guard goals[index].status == .active else { return }
                    goals[index].toggleStage(stage.id)
                    saveGoals()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: stage.isDone ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(stage.isDone ? LifeTheme.accent : LifeTheme.textTertiary)
                        Text(stage.title)
                            .font(.subheadline)
                            .foregroundStyle(stage.isDone ? LifeTheme.textSecondary : LifeTheme.textPrimary)
                            .strikethrough(stage.isDone)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .disabled(goals[index].status != .active)

                if goal.status == .active {
                    Button {
                        withAnimation(.snappy) {
                            checkInStageId = (checkInStageId == stage.id) ? nil : stage.id
                            checkInNote = ""
                        }
                    } label: {
                        Image(systemName: checkInStageId == stage.id ? "square.and.pencil.circle.fill" : "square.and.pencil.circle")
                            .font(.title3)
                            .foregroundStyle(LifeTheme.accent)
                    }
                    .buttonStyle(.plain)
                }
            }

            let records = goal.checkIns(for: stage.id)
            if !records.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(records) { record in
                        checkInRow(record)
                    }
                }
                .padding(.leading, 32)
            }

            if checkInStageId == stage.id, goal.status == .active {
                VStack(alignment: .leading, spacing: 10) {
                    Stepper(value: $checkInMinutes, in: 5...480, step: 5) {
                        Text("\(checkInMinutes) 分鐘")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(LifeTheme.textPrimary)
                    }

                    TextField("這次做了什麼？狀況如何？", text: $checkInNote, axis: .vertical)
                        .lineLimit(1...3)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
                        .foregroundStyle(LifeTheme.textPrimary)

                    Button {
                        goals[index].addCheckIn(
                            minutes: checkInMinutes,
                            note: checkInNote.trimmingCharacters(in: .whitespacesAndNewlines),
                            stageId: stage.id
                        )
                        checkInNote = ""
                        withAnimation(.snappy) { checkInStageId = nil }
                        saveGoals()
                    } label: {
                        Label("打卡", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(LifeTheme.accent.opacity(0.18)))
                            .foregroundStyle(LifeTheme.accent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03)))
                .padding(.leading, 32)
            }
        }
    }

    // 修改内容 — 單筆打卡紀錄列
    func checkInRow(_ record: GoalCheckIn) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(formatDate(record.date))
                .font(.caption.monospacedDigit())
                .foregroundStyle(LifeTheme.textTertiary)
            Text("\(record.minutes) 分鐘")
                .font(.caption.monospacedDigit())
                .foregroundStyle(LifeTheme.accent)
            if !record.note.isEmpty {
                Text(record.note)
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textSecondary)
            }
            Spacer()
        }
    }

    func notesSection(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("備註")
                .font(.headline)
                .foregroundStyle(LifeTheme.textPrimary)
            TextField("書名、地點、想記下的事…", text: Binding(
                get: { goals[index].notes },
                set: {
                    goals[index].notes = $0
                    saveGoals()
                }
            ), axis: .vertical)
            .lineLimit(2...5)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
            .foregroundStyle(LifeTheme.textPrimary)
        }
        .cardStyle()
    }

    // 修改内容 — 時間規劃重構：任務總長/每週投入 stepper、預計完成推算、開始日期＋執行時間
    func timePlanningSection(index: Int, goal: LifeGoal) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("時間規劃")
                .font(.headline)
                .foregroundStyle(LifeTheme.textPrimary)

            HStack(spacing: 12) {
                hourStepper(
                    title: "任務總長",
                    text: "\(goals[index].estimatedHours ?? 0) 小時",
                    onDecrease: {
                        goals[index].estimatedHours = max(1, (goals[index].estimatedHours ?? 1) - 1)
                        saveGoalsAndSyncCalendar(index: index)
                    },
                    onIncrease: {
                        goals[index].estimatedHours = min(2000, (goals[index].estimatedHours ?? 0) + 1)
                        saveGoalsAndSyncCalendar(index: index)
                    }
                )

                hourStepper(
                    title: "每週投入",
                    text: String(format: "%.1f 小時", goal.effectiveWeeklyHours),
                    onDecrease: {
                        goals[index].weeklyHours = max(0.5, goal.effectiveWeeklyHours - 0.5)
                        saveGoalsAndSyncCalendar(index: index)
                    },
                    onIncrease: {
                        goals[index].weeklyHours = min(80, goal.effectiveWeeklyHours + 0.5)
                        saveGoalsAndSyncCalendar(index: index)
                    }
                )
            }

            if let weeks = goal.estimatedWeeks, let date = goal.estimatedCompletionDate {
                HStack {
                    Text("預計完成")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textTertiary)
                    Spacer()
                    Text("約 \(weeks) 週 · \(formatDate(date))")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(LifeTheme.accent)
                }
            }

            DatePicker(
                "開始日期",
                selection: Binding(
                    get: { goals[index].timePlan.startDate },
                    set: {
                        goals[index].timePlan.startDate = $0
                        saveGoalsAndSyncCalendar(index: index)
                    }
                ),
                displayedComponents: .date
            )
            .tint(LifeTheme.accent)

            DatePicker(
                "執行時間",
                selection: Binding(
                    get: { goals[index].timePlan.execTime },
                    set: {
                        goals[index].timePlan.execTime = $0
                        saveGoalsAndSyncCalendar(index: index)
                    }
                ),
                displayedComponents: .hourAndMinute
            )
            .tint(LifeTheme.accent)

            Toggle(isOn: $calendarSyncEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("同步到 Apple 日曆")
                        .font(.subheadline)
                        .foregroundStyle(LifeTheme.textPrimary)
                    Text("每週 \(goal.weeklySessionCount) 次、每次 1 小時，重複至預計完成日")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textTertiary)
                }
            }
            .tint(LifeTheme.accent)
            .onAppear {
                calendarSyncEnabled = !goal.timePlan.calendarEventIdentifiers.isEmpty
            }
            .onChange(of: calendarSyncEnabled) { _, enabled in
                Task {
                    if enabled {
                        let ids = await AppleCalendarManager.shared.syncGoal(goals[index])
                        goals[index].timePlan.calendarEventIdentifiers = ids
                    } else {
                        AppleCalendarManager.shared.removeEvents(identifiers: goals[index].timePlan.calendarEventIdentifiers)
                        goals[index].timePlan.calendarEventIdentifiers = []
                    }
                    saveGoals()
                }
            }
        }
        .cardStyle()
    }

    // 修改内容 — − / ＋ 調整元件
    func hourStepper(title: String, text: String, onDecrease: @escaping () -> Void, onIncrease: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(LifeTheme.textTertiary)
            HStack(spacing: 0) {
                Button(action: onDecrease) {
                    Image(systemName: "minus")
                        .frame(width: 32, height: 28)
                }
                .buttonStyle(.plain)
                .foregroundStyle(LifeTheme.accent)

                Text(text)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(LifeTheme.textPrimary)
                    .frame(maxWidth: .infinity)

                Button(action: onIncrease) {
                    Image(systemName: "plus")
                        .frame(width: 32, height: 28)
                }
                .buttonStyle(.plain)
                .foregroundStyle(LifeTheme.accent)
            }
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
        }
    }

    func remindersToggle(index: Int, goal: LifeGoal) -> some View {
        Toggle(isOn: $remindersEnabled) {
            VStack(alignment: .leading, spacing: 4) {
                Text("同步到提醒事項")
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textPrimary)
                Text("在「LifeSubtraction」清單建立提醒")
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textTertiary)
            }
        }
        .tint(LifeTheme.accent)
        .cardStyle(padding: 16)
        .onAppear {
            remindersEnabled = goal.reminderIdentifier != nil
        }
        .onChange(of: remindersEnabled) { _, enabled in
            Task {
                if enabled {
                    let id = await RemindersManager.shared.syncGoal(goals[index])
                    goals[index].reminderIdentifier = id
                } else {
                    RemindersManager.shared.removeReminder(identifier: goals[index].reminderIdentifier)
                    goals[index].reminderIdentifier = nil
                }
                saveGoals()
            }
        }
    }

    func completedSummary(_ goal: LifeGoal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let start = goal.startDate {
                detailRow("開始", formatDate(start))
            }
            if let end = goal.completedDate {
                detailRow("完成", formatDate(end))
            }
            if let days = goal.durationDays {
                detailRow("共花費", "\(days) 天")
            }
        }
        .cardStyle()
    }

    func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(LifeTheme.textTertiary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textPrimary)
        }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }

    func completeGoal(at index: Int) {
        goals[index].markCompleted()
        let moment = LifeMoment(from: goals[index])
        moments.insert(moment, at: 0)
        saveGoals()
        saveMoments()
        showCompletionSheet = true
    }

    func deleteGoal() {
        guard let index = goalIndex else { return }
        RemindersManager.shared.removeReminder(identifier: goals[index].reminderIdentifier)
        AppleCalendarManager.shared.removeEvents(identifiers: goals[index].timePlan.calendarEventIdentifiers) // 修改内容
        goals.remove(at: index)
        saveGoals()
        dismiss()
    }

    func addSuggestedGoal(title: String, category: GoalCategory) {
        goals.insert(
            LifeGoal(
                title: title,
                category: category,
                stages: GoalStageGenerator.makeStages(catalogId: nil, title: title, category: category)
            ),
            at: 0
        )
        saveGoals()
    }

    func saveGoals() {
        LocalJSONStore.save(goals, key: StorageKey.lifeGoals)
    }

    func saveGoalsAndSyncCalendar(index: Int) {
        saveGoals()
        guard calendarSyncEnabled, goals.indices.contains(index) else { return }
        Task {
            let ids = await AppleCalendarManager.shared.syncGoal(goals[index]) // 修改内容
            goals[index].timePlan.calendarEventIdentifiers = ids // 修改内容
            saveGoals()
        }
    }

    func saveMoments() {
        LocalJSONStore.save(moments, key: StorageKey.lifeMoments)
    }
}

// MARK: - Completion Sheet

struct GoalCompletionSheet: View {
    let goal: LifeGoal
    let onAddSuggestion: (String, GoalCategory) -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 44))
                            .foregroundStyle(LifeTheme.accent)
                        Text("你做到了。")
                            .font(.title2.bold())
                            .foregroundStyle(LifeTheme.textPrimary)
                        Text(goal.title)
                            .font(.headline)
                            .foregroundStyle(LifeTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)

                    Text("已加入人生時刻")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textTertiary)

                    Text("你想繼續成長嗎？")
                        .font(.headline)
                        .foregroundStyle(LifeTheme.textPrimary)

                    ForEach(GoalRecommender.suggestions(after: goal), id: \.title) { item in
                        Button {
                            onAddSuggestion(item.title, item.category)
                        } label: {
                            HStack {
                                Image(systemName: item.category.iconName)
                                    .foregroundStyle(LifeTheme.accent)
                                Text(item.title)
                                    .foregroundStyle(LifeTheme.textPrimary)
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(LifeTheme.accent)
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(LifeTheme.glassFill))
                        }
                        .buttonStyle(.plain)
                    }

                    SecondaryButton("稍後再說", action: onDismiss)
                }
                .padding()
            }
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("完成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉", action: onDismiss)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
