import SwiftUI

// MARK: - TaskListView
// 所有人生小任務的清單，以「完成難度/時間」分組，不是依類別。
// 也提供進入 LifeGoalsView（大目標）的入口。

struct TaskListView: View {
    @State private var tasks: [LifeTask] = []
    @State private var searchText = ""
    @State private var selectedCategory: GoalCategory? = nil
    @State private var showingAdd = false
    @State private var completingTask: LifeTask?
    @State private var showingGoals = false
    @State private var deletingTask: LifeTask?

    var filteredTasks: [LifeTask] {
        tasks.filter { task in
            guard !task.isArchived else { return false }
            let matchesCategory = selectedCategory == nil || task.category == selectedCategory
            let matchesSearch = searchText.isEmpty ||
                task.title.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    var pendingTasks: [LifeTask] { filteredTasks.filter { $0.isPending } }
    var completedTasks: [LifeTask] { filteredTasks.filter { $0.isCompleted } }

    var starredTasks: [LifeTask]   { pendingTasks.filter { $0.isStarred } }
    var quickTasks: [LifeTask]     { pendingTasks.filter { !$0.isStarred && $0.isQuick } }
    var planTasks: [LifeTask]      { pendingTasks.filter { !$0.isStarred && !$0.isQuick && $0.estimatedMinutes != nil } }
    var somedayTasks: [LifeTask]   { pendingTasks.filter { !$0.isStarred && $0.estimatedMinutes == nil } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 搜尋列
                    searchBar
                        .padding(.horizontal)

                    // 類別 filter chips
                    categoryChips
                        .padding(.horizontal)

                    // 任務分組
                    if pendingTasks.isEmpty && completedTasks.isEmpty {
                        emptyState
                            .padding(.horizontal)
                    } else {
                        taskGroups
                            .padding(.horizontal)

                        if !completedTasks.isEmpty {
                            completedSection
                                .padding(.horizontal)
                        }
                    }

                    // 大目標入口
                    bigGoalsLink
                        .padding(.horizontal)

                    Spacer(minLength: 20)
                }
                .padding(.vertical, 16)
            }
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("清單")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(LifeTheme.accent)
                            .font(.system(size: 20))
                    }
                }
            }
            .onAppear { loadTasks() }
            .sheet(isPresented: $showingAdd, onDismiss: { loadTasks() }) {
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
            .sheet(isPresented: $showingGoals) {
                NavigationStack {
                    LifeGoalsView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("關閉") { showingGoals = false }
                                    .foregroundStyle(LifeTheme.textSecondary)
                            }
                        }
                }
            }
            .alert("確定刪除？", isPresented: Binding(
                get: { deletingTask != nil },
                set: { if !$0 { deletingTask = nil } }
            ), presenting: deletingTask) { task in
                Button("刪除", role: .destructive) { archiveTask(task) }
                Button("取消", role: .cancel) {}
            } message: { task in
                Text("「\(task.title)」將被移除。")
            }
        }
    }

    // MARK: - Search Bar

    var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(LifeTheme.textTertiary)
                .font(.subheadline)
            TextField("搜尋", text: $searchText)
                .foregroundStyle(LifeTheme.textPrimary)
        }
        .padding(.horizontal, 12)
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

    // MARK: - Category Chips

    var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chipButton(title: "全部", icon: "square.grid.2x2", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(GoalCategory.allCases) { cat in
                    chipButton(title: cat.displayName, icon: cat.iconName, isSelected: selectedCategory == cat) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    func chipButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.caption2)
                Text(title).font(.caption)
            }
            .foregroundStyle(isSelected ? LifeTheme.accent : LifeTheme.textSecondary)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(isSelected ? LifeTheme.accentSoft : LifeTheme.glassFill)
            )
            .overlay(
                Capsule().stroke(
                    isSelected ? LifeTheme.accent.opacity(0.4) : LifeTheme.glassBorder,
                    lineWidth: 0.5
                )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Task Groups

    var taskGroups: some View {
        VStack(spacing: 16) {
            if !starredTasks.isEmpty {
                taskSection(title: "⭐ 釘選", tasks: starredTasks)
            }
            if !quickTasks.isEmpty {
                taskSection(title: "⚡ 快速完成（1小時內）", tasks: quickTasks)
            }
            if !planTasks.isEmpty {
                taskSection(title: "📅 需要安排", tasks: planTasks)
            }
            if !somedayTasks.isEmpty {
                taskSection(title: "🌙 有一天", tasks: somedayTasks)
            }
        }
    }

    func taskSection(title: String, tasks: [LifeTask]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(LifeTheme.textTertiary)
                .padding(.leading, 2)

            VStack(spacing: 6) {
                ForEach(tasks) { task in
                    taskRow(task)
                }
            }
        }
    }

    func taskRow(_ task: LifeTask) -> some View {
        HStack(spacing: 12) {
            // 完成圓圈
            Button {
                completingTask = task
            } label: {
                Image(systemName: "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(LifeTheme.textTertiary)
            }
            .buttonStyle(.plain)

            // 內容
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textPrimary)

                HStack(spacing: 6) {
                    Image(systemName: task.category.iconName)
                        .font(.caption2)
                        .foregroundStyle(LifeTheme.accent)
                    Text(task.category.displayName)
                        .font(.caption2)
                        .foregroundStyle(LifeTheme.textTertiary)
                    if !task.estimatedLabel.isEmpty {
                        Text("·")
                            .foregroundStyle(LifeTheme.textQuaternary)
                            .font(.caption2)
                        Text(task.estimatedLabel)
                            .font(.caption2)
                            .foregroundStyle(LifeTheme.textTertiary)
                    }
                }
            }

            Spacer()

            // 釘選標誌
            if task.isStarred {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(LifeTheme.warm)
            }
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
        .swipeActions(edge: .leading) {
            Button {
                toggleStar(task)
            } label: {
                Label(task.isStarred ? "取消釘選" : "釘選", systemImage: task.isStarred ? "star.slash" : "star.fill")
            }
            .tint(LifeTheme.warm)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deletingTask = task
            } label: {
                Label("刪除", systemImage: "trash")
            }
        }
    }

    // MARK: - Completed Section

    @State private var showCompleted = false

    var completedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.snappy) { showCompleted.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: showCompleted ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                    Text("已完成 (\(completedTasks.count))")
                        .font(.caption.weight(.medium))
                    Spacer()
                }
                .foregroundStyle(LifeTheme.textTertiary)
                .padding(.leading, 2)
            }
            .buttonStyle(.plain)

            if showCompleted {
                VStack(spacing: 6) {
                    ForEach(completedTasks.prefix(10)) { task in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(LifeTheme.accent.opacity(0.6))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(.subheadline)
                                    .foregroundStyle(LifeTheme.textTertiary)
                                    .strikethrough(true, color: LifeTheme.textQuaternary)

                                if let date = task.completedAt {
                                    Text(date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption2)
                                        .foregroundStyle(LifeTheme.textQuaternary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.02))
                        )
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 36))
                .foregroundStyle(LifeTheme.accent.opacity(0.7))
            Text("還沒有任何待辦")
                .font(.headline)
                .foregroundStyle(LifeTheme.textPrimary)
            Text("把想做的事記下來，\n不管多小都算數。")
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)
                .multilineTextAlignment(.center)
            PrimaryButton("加入第一件事", icon: "plus") {
                showingAdd = true
            }
        }
        .padding(.vertical, 8)
        .cardStyle(padding: 24)
    }

    // MARK: - Big Goals Link

    var bigGoalsLink: some View {
        Button { showingGoals = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "target")
                    .font(.system(size: 18))
                    .foregroundStyle(LifeTheme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("人生大目標")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(LifeTheme.textPrimary)
                    Text("學語言、跑馬拉松、環遊世界…")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textQuaternary)
            }
            .cardStyle(padding: 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    func toggleStar(_ task: LifeTask) {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[idx].isStarred.toggle()
        saveTasks()
    }

    func completeTask(_ task: LifeTask, note: String?) {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[idx].complete(note: note)
        saveTasks()
    }

    func archiveTask(_ task: LifeTask) {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[idx].isArchived = true
        saveTasks()
    }

    func saveTasks() {
        LocalJSONStore.save(tasks, key: StorageKey.lifeTasks)
    }

    func loadTasks() {
        tasks = LocalJSONStore.load([LifeTask].self, key: StorageKey.lifeTasks, defaultValue: [])
    }
}

#Preview {
    TaskListView()
}
