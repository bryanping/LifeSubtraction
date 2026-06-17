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
    @State private var isEditingStages = false

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
        .navigationTitle(goals.first(where: { $0.id == goalId })?.displayTitle ?? "人生目標")
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
                VStack(alignment: .leading, spacing: 12) {
                    Text("進度")
                        .font(.headline)
                        .foregroundStyle(LifeTheme.textPrimary)

                    ForEach(goal.stages) { stage in
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
                    }
                }
                .cardStyle()
            }
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
