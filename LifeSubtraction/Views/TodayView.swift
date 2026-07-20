import SwiftUI

// MARK: - TodayView
// 主要入口：每天打開 app 第一個看到的畫面。
// 核心邏輯：推薦一件今天能做的事，而不是讓用戶自己選。

struct TodayView: View {
    @EnvironmentObject var store: LifeStore

    @State private var tasks: [LifeTask] = []
    @State private var goals: [LifeGoal] = [] // 修改内容 — 加載大目標，供語錄/反思客製化
    @State private var reflectionDraft = ""
    @State private var reflectionEntries: [ReflectionEntry] = []
    @State private var showingHistory = false
    @State private var showingAddTask = false
    @State private var completingTask: LifeTask?

    private var primary: LifeTask? { TaskRecommender.primary(from: tasks) }
    private var secondary: [LifeTask] { TaskRecommender.secondary(from: tasks, primaryId: primary?.id) }

    // 修改内容 — 客製化語錄/反思，依今日推薦任務類別或用戶清單主要類別選取
    private var dailyReminderText: String {
        DailyReminder.today(primaryTask: primary, allTasks: tasks, goals: goals)
    }
    private var reflectionPromptText: String {
        DailyReflectionPrompt.today(primaryTask: primary, allTasks: tasks, goals: goals)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    greetingSection
                        .padding(.horizontal)

                    if tasks.filter({ $0.isCurrentlyActive }).isEmpty {
                        emptyStateCard
                            .padding(.horizontal)
                    } else {
                        if let p = primary {
                            primaryCard(p)
                                .padding(.horizontal)
                        }
                        if !secondary.isEmpty {
                            secondarySection
                                .padding(.horizontal)
                        }
                    }

                    dailyReflectionCard
                        .padding(.horizontal)

                    Spacer(minLength: 20)
                }
                .padding(.vertical, 2)
            }
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("今天")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddTask = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(LifeTheme.accent)
                            .font(.system(size: 20))
                    }
                }
            }
            .onAppear { loadData() }
            .sheet(isPresented: $showingHistory, onDismiss: { loadData() }) {
                ReflectionHistoryView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingAddTask, onDismiss: { loadData() }) {
                AddTaskView { newTask in
                    tasks.append(newTask)
                    saveTasks()
                }
            }
            .sheet(item: $completingTask) { task in
                TaskCompleteSheet(task: task) { note in
                    completeTask(task, note: note)
                }
            }
        }
    }

    // MARK: - Greeting

    var greetingSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(LifeTheme.textPrimary)
                Text(dailyReminderText) // 修改内容 — 改用客製化語錄
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.top, 4)
    }

    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "早安 ☀️"
        case 12..<18: return "午安 🌤"
        case 18..<22: return "晚安 🌙"
        default:      return "夜深了 🌌"
        }
    }

    // MARK: - Primary Card

    func primaryCard(_ task: LifeTask) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("今天可以做這件事", systemImage: "sparkles")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(LifeTheme.accent)
                Spacer()
                Image(systemName: task.category.iconName)
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textTertiary)
            }

            Text(task.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(LifeTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let label = task.estimatedMinutes.map({ LifeTask(title: "", estimatedMinutes: $0).estimatedLabel }),
               !label.isEmpty {
                Text("約 \(label)")
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textTertiary)
            }

            HStack(spacing: 10) {
                Button {
                    completingTask = task
                } label: {
                    Label("完成", systemImage: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            Capsule().fill(LifeTheme.heroGradient)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    snoozeTask(task, days: 7)
                } label: {
                    Text("改天")
                        .font(.subheadline)
                        .foregroundStyle(LifeTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.06))
                                .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .cardStyle(padding: 18)
    }

    // MARK: - Secondary Section

    var secondarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("也許還有時間")
                .font(.caption.weight(.medium))
                .foregroundStyle(LifeTheme.textTertiary)
                .padding(.leading, 2)

            ForEach(secondary) { task in
                HStack(spacing: 12) {
                    Image(systemName: task.category.iconName)
                        .font(.caption)
                        .foregroundStyle(LifeTheme.accent)
                        .frame(width: 20)

                    Text(task.title)
                        .font(.subheadline)
                        .foregroundStyle(LifeTheme.textSecondary)

                    Spacer()

                    if let label = task.estimatedMinutes.map({ LifeTask(title: "", estimatedMinutes: $0).estimatedLabel }),
                       !label.isEmpty {
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(LifeTheme.textQuaternary)
                    }

                    Button {
                        completingTask = task
                    } label: {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(LifeTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LifeTheme.glassFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
                )
            }
        }
    }

    // MARK: - Empty State

    var emptyStateCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "checklist")
                .font(.system(size: 36))
                .foregroundStyle(LifeTheme.accent.opacity(0.7))
            Text("清單還是空的")
                .font(.headline)
                .foregroundStyle(LifeTheme.textPrimary)
            Text("加入幾件你想做的小事，我每天幫你挑一件。")
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)
                .multilineTextAlignment(.center)
            PrimaryButton("加入第一件事", icon: "plus") {
                showingAddTask = true
            }
        }
        .padding(.vertical, 8)
        .cardStyle(padding: 24)
    }

    // MARK: - Daily Reflection

    var dailyReflectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("每日反思")
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)
                Spacer()
                Button {
                    showingHistory = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption)
                        Text("歷史")
                            .font(.caption)
                    }
                    .foregroundStyle(LifeTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }

            Text(reflectionPromptText) // 修改内容 — 改用客製化反思問題
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)

            TextField("寫下一句話…", text: $reflectionDraft, axis: .vertical)
                .lineLimit(2...4)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )
                .foregroundStyle(LifeTheme.textPrimary)

            HStack {
                if hasSavedToday {
                    Label("已記錄", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.accent.opacity(0.8))
                }
                Spacer()
                Button(action: saveReflection) {
                    Text("保存")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(
                            reflectionDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? LifeTheme.textTertiary
                                : LifeTheme.accent
                        )
                }
                .disabled(reflectionDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.plain)
            }
        }
        .cardStyle()
    }

    var hasSavedToday: Bool {
        ReflectionEntry.current(in: reflectionEntries, period: .daily) != nil
    }

    // MARK: - Actions

    func snoozeTask(_ task: LifeTask, days: Int) {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[idx].snoozeForDays(days)
        saveTasks()
    }

    func completeTask(_ task: LifeTask, note: String?) {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[idx].complete(note: note)
        saveTasks()
    }

    func saveReflection() {
        let trimmed = reflectionDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        ReflectionEntry.upsert(text: trimmed, period: .daily, in: &reflectionEntries)
        LocalJSONStore.save(reflectionEntries, key: ReflectionEntry.storageKey)
    }

    func saveTasks() {
        LocalJSONStore.save(tasks, key: StorageKey.lifeTasks)
    }

    func loadData() {
        tasks = LocalJSONStore.load([LifeTask].self, key: StorageKey.lifeTasks, defaultValue: [])
        // 修改内容 — 載入大目標，讓語錄/反思可依用戶目標類別客製化
        goals = LocalJSONStore.load([LifeGoal].self, key: StorageKey.lifeGoals, defaultValue: [])
        reflectionEntries = LocalJSONStore.load(
            [ReflectionEntry].self,
            key: ReflectionEntry.storageKey,
            defaultValue: []
        )
        reflectionDraft = ReflectionEntry.current(in: reflectionEntries, period: .daily)?.text ?? ""
    }
}

// MARK: - TaskCompleteSheet

struct TaskCompleteSheet: View {
    let task: LifeTask
    let onComplete: (String?) -> Void

    @State private var note = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 完成標題區
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(LifeTheme.accent)

                    Text("完成了！")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(LifeTheme.textPrimary)

                    Text(task.title)
                        .font(.headline)
                        .foregroundStyle(LifeTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 16)

                // 感想輸入
                VStack(alignment: .leading, spacing: 8) {
                    Text("記下感受（可選）")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textTertiary)

                    TextField("這次的感受是…", text: $note, axis: .vertical)
                        .lineLimit(3...5)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(LifeTheme.glassFill)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
                        )
                        .foregroundStyle(LifeTheme.textPrimary)
                }
                .padding(.horizontal)

                Spacer()

                // 按鈕
                VStack(spacing: 10) {
                    PrimaryButton("儲存回憶") {
                        onComplete(note.isEmpty ? nil : note)
                        dismiss()
                    }
                    .padding(.horizontal)

                    Button("跳過") {
                        onComplete(nil)
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textTertiary)
                }
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(LifeTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    TodayView()
        .environmentObject(LifeStore())
        .environmentObject(StoreManager.shared)
}
