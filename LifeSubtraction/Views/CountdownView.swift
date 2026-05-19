import SwiftUI

// 修改内容
struct CountdownView: View {
    @EnvironmentObject var store: LifeStore

    @State private var lifeGoals: [LifeGoal] = []
    @State private var reflectionEntries: [ReflectionEntry] = []
    @State private var reflectionPeriod: ReflectionPeriod = .daily
    @State private var reflectionDraft = ""
    @State private var regretItems: [RegretAvoidanceItem] = []
    @State private var alignmentRecord: LifeAlignmentRecord?
    @State private var showingReflectionHistory = false
    @State private var showingAddGoal = false
    @State private var showingAddRegret = false
    @State private var showingAddMoment = false
    @State private var remainingMomentItems: [RemainingMomentItem] = []
    @State private var remainingMomentRecords: [RemainingMomentRecord] = []
    @State private var deletingItem: RemainingMomentItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    countdownHeader
                        .padding(.horizontal)

                    remainingMomentsSection
                        .padding(.horizontal)

             //       goalCard
              //          .padding(.horizontal)

                    reflectionJournalCard
                        .padding(.horizontal)

                    lifeAlignmentCard
                        .padding(.horizontal)

                    regretAvoidanceCard
                        .padding(.horizontal)

                    Spacer(minLength: 20)
                }
                .padding(.vertical, 16)
            }
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("今日倒數")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: RemainingMomentItem.self) { item in
                RemainingMomentDetailView(item: item)
                    .environmentObject(store)
                    .onDisappear {
                        reloadRemainingMomentRecords()
                    }
            }
            .onAppear {
                loadAllData()
            }
            .sheet(isPresented: $showingReflectionHistory) {
                ReflectionHistoryView()
            }
            .sheet(isPresented: $showingAddMoment) {
                AddRemainingMomentView { newItem in
                    remainingMomentItems.append(newItem)
                    saveRemainingMomentItems()
                }
            }
            .alert(
                "刪除項目？",
                isPresented: Binding(
                    get: { deletingItem != nil },
                    set: { if !$0 { deletingItem = nil } }
                ),
                presenting: deletingItem
            ) { item in
                Button("刪除", role: .destructive) {
                    archiveRemainingMoment(item)
                    deletingItem = nil
                }
                Button("取消", role: .cancel) {
                    deletingItem = nil
                }
            } message: { item in
                Text("「\(item.title)」將被移至封存。")
            }
        }
    }

    // MARK: - Countdown Header (aligned with OverviewView hero)

    var countdownHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 20) {
                LifeRemainingRing(percent: store.metrics.percentRemaining)
                    .frame(width: 116, height: 116)

                VStack(alignment: .leading, spacing: 14) {
                    Text("這可能是你剩下的人生")
                        .font(.subheadline)
                        .foregroundStyle(LifeTheme.textSecondary)

                    (
                        Text("還剩下 ")
                        + Text(formattedCount(store.daysRemaining))
                            .foregroundStyle(LifeTheme.warm)
                            .fontWeight(.semibold)
                        + Text(" 天")
                    )
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 10) {
                        countdownDetailRow(
                            icon: "calendar",
                            text: "約 \(store.metrics.yearsRemaining) 年 · \(store.monthsRemaining) 個月"
                        )
                        countdownDetailRow(
                            icon: "clock.badge.checkmark",
                            text: "還有 \(formattedCount(store.weeksRemaining)) 週可把握"
                        )
                    }
                }
            }

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5)

            HStack(spacing: 0) {
                countdownBreakdownPill(
                    label: "年",
                    value: "\(store.metrics.yearsRemaining)"
                )
                breakdownDivider
                countdownBreakdownPill(
                    label: "月",
                    value: "\(store.monthsRemaining)"
                )
                breakdownDivider
                countdownBreakdownPill(
                    label: "週",
                    value: "\(store.weeksRemaining)"
                )
            }

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5)

            HStack(alignment: .center) {
                Label {
                    Text("預計壽命 \(store.lifeExpectancy) 歲")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textTertiary)
                } icon: {
                    Image(systemName: "hourglass")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textTertiary)
                }

                Spacer()

                TimelineView(.periodic(from: Date(), by: 1)) { context in
                    Label {
                        Text("今天還剩 \(remainingTodayText(now: context.date))")
                            .font(.caption)
                            .foregroundStyle(LifeTheme.accent)
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "sun.horizon.fill")
                            .font(.caption)
                            .foregroundStyle(LifeTheme.accent)
                    }
                }
            }
        }
        .cardStyle()
    }

    var breakdownDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 0.5, height: 36)
    }

    func countdownDetailRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(LifeTheme.warm)
                .frame(width: 16, alignment: .center)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    func countdownBreakdownPill(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(LifeTheme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(LifeTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    func formattedCount(_ value: Int) -> String {
        value.formatted(.number.grouping(.automatic))
    }
    // MARK: - Remaining Moments

    var remainingMomentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("你還有幾次？")
                    .font(.headline)
                    .foregroundStyle(Color.primary)

                Spacer()

                Button(action: { showingAddMoment = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.accentColor)
                }
                .contentShape(Rectangle())
            }

            if activeRemainingMomentItems.isEmpty {
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.secondary)
                    Text("添加你的第一個項目")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    ForEach(activeRemainingMomentItems) { item in
                        NavigationLink(value: item) {
                            momentRowCard(for: item)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                deletingItem = item
                            } label: {
                                Label("刪除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }

    var activeRemainingMomentItems: [RemainingMomentItem] {
        remainingMomentItems.filter { !$0.isArchived }
    }

    func momentRowCard(for item: RemainingMomentItem) -> some View {
        RemainingMomentRow(
            item: item,
            count: estimatedRemainingCount(for: item)
        )
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.gray.opacity(0.18), lineWidth: 0.8)
        )
    }

    func archiveRemainingMoment(_ item: RemainingMomentItem) {
        guard let index = remainingMomentItems.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        remainingMomentItems[index].isArchived = true
        saveRemainingMomentItems()
    }

    func estimatedRemainingCount(for item: RemainingMomentItem) -> Int {
        let remainingYears: Int

        switch item.dependsOn {
        case .selfLife:
            remainingYears = max(0, store.lifeExpectancy - store.ageYears)
        case .parents:
            remainingYears = max(0, store.parentYearsRemaining)
        }

        let completedCount = remainingMomentRecords.filter { $0.itemId == item.id }.count
        return max(0, remainingYears * item.estimatedTimesPerYear() - completedCount)
    }

    func saveRemainingMomentItems() {
        LocalJSONStore.save(remainingMomentItems, key: "remaining-moment-items")
    }

 

    // MARK: - Goal Card - 修改内容
    var goalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("人生目標")
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                Spacer()
                Button(action: { showingAddGoal = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }

            Text("你真正想完成什麼？")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)

            if lifeGoals.isEmpty {
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: "target")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.secondary)
                    Text("還沒有設定目標")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(lifeGoals) { goal in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(goal.title)
                                    .font(.subheadline)
                                    .foregroundStyle(goal.isCompleted ? Color.secondary : Color.primary)
                                    .strikethrough(goal.isCompleted)

                                ProgressView(value: goal.progress)
                                    .tint(goal.isCompleted ? Color.green : Color.accentColor)
                            }
                            if goal.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.green)
                            }
                        }
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
        )
        .sheet(isPresented: $showingAddGoal) {
            AddGoalSheet { newGoal in
                lifeGoals.append(newGoal)
                saveGoals()
            }
        }
    }

    // MARK: - Reflection Journal (daily + weekly)

    var reflectionJournalCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("反思紀錄")
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)
                Spacer()
                Button(action: { showingReflectionHistory = true }) {
                    Text("歷史")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.accent)
                }
            }

            Picker("週期", selection: $reflectionPeriod) {
                ForEach(ReflectionPeriod.allCases) { period in
                    Text(period.displayName).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: reflectionPeriod) { _, _ in
                syncReflectionDraftFromStore()
            }

            Text(reflectionPeriod.prompt)
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let saved = currentReflectionEntry, reflectionDraft == saved.text {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(LifeTheme.accent)
                    Text(reflectionPeriod.savedHint)
                        .font(.caption)
                        .foregroundStyle(LifeTheme.accent)
                }
            }

            TextEditor(text: $reflectionDraft)
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(reflectionFieldBackground)
                .foregroundStyle(LifeTheme.textPrimary)

            Button(action: saveReflectionJournal) {
                Text(reflectionPeriod.saveButtonTitle)
                    .font(.headline)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule().fill(
                            reflectionDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? AnyShapeStyle(Color.white.opacity(0.15))
                                : AnyShapeStyle(LifeTheme.heroGradient)
                        )
                    )
            }
            .disabled(reflectionDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .cardStyle()
    }

    private var reflectionFieldBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.white.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
            )
    }

    private var currentReflectionEntry: ReflectionEntry? {
        ReflectionEntry.current(in: reflectionEntries, period: reflectionPeriod)
    }

    private func syncReflectionDraftFromStore() {
        reflectionDraft = currentReflectionEntry?.text ?? ""
    }

    private func saveReflectionJournal() {
        let trimmed = reflectionDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        ReflectionEntry.upsert(text: trimmed, period: reflectionPeriod, in: &reflectionEntries)
        LocalJSONStore.save(reflectionEntries, key: ReflectionEntry.storageKey)
    }

    private func loadReflectionJournal() {
        reflectionEntries = LocalJSONStore.load(
            [ReflectionEntry].self,
            key: ReflectionEntry.storageKey,
            defaultValue: []
        )
        if ReflectionEntry.migrateLegacyWeeklyFocus(into: &reflectionEntries) {
            LocalJSONStore.save(reflectionEntries, key: ReflectionEntry.storageKey)
        }
        syncReflectionDraftFromStore()
    }

    // MARK: - Life Alignment Card - 修改内容
    var lifeAlignmentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("人生對齊")
                .font(.headline)
                .foregroundStyle(Color.primary)

            Text("今天的行動，有接近你想成為的人嗎？")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)

            VStack(spacing: 8) {
                ForEach(LifeAlignmentLevel.allCases) { level in
                    Button(action: { selectAlignment(level) }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(level.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(
                                        alignmentRecord?.level == level ? Color.white : Color.primary
                                    )
                            }
                            Spacer()
                            if alignmentRecord?.level == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.white)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            alignmentRecord?.level == level ?
                            Color.accentColor :
                            Color(.systemGray6)
                        )
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - Regret Avoidance Card - 修改内容
    var regretAvoidanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("避免遺憾")
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                Spacer()
                Button(action: { showingAddRegret = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }

            Text("80歲的你，會後悔什麼沒做？")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)

            if regretItems.isEmpty {
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: "lightbulb.2")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.secondary)
                    Text("添加重要的事")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(regretItems.prefix(3))) { item in
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.primary)

                                Text(item.status.displayName)
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                            }
                            Spacer()
                            statusBadge(for: item.status)
                        }
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
        )
        .sheet(isPresented: $showingAddRegret) {
            AddRegretSheet { newItem in
                regretItems.append(newItem)
                saveRegretItems()
            }
        }
    }

    func statusBadge(for status: RegretStatus) -> some View {
        Group {
            switch status {
            case .notStarted:
                Image(systemName: "circle")
                    .foregroundStyle(Color.gray)
            case .inProgress:
                Image(systemName: "circle.fill")
                    .foregroundStyle(Color.orange)
            case .handled:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.green)
            }
        }
    }

    // MARK: - Helper Functions
    func remainingTodayText(now: Date = Date()) -> String {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else {
            return "--:--:--"
        }

        let seconds = max(0, Int(tomorrow.timeIntervalSince(now)))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }

    func saveGoals() {
        LocalJSONStore.save(lifeGoals, key: "life-goals")
    }

    func saveRegretItems() {
        LocalJSONStore.save(regretItems, key: "regret-avoidance-items")
    }

    func selectAlignment(_ level: LifeAlignmentLevel) {
        alignmentRecord = LifeAlignmentRecord(date: Date(), level: level)
        let todayKey = "alignment-\(DateFormatter.dateKey(for: Date()))"
        LocalJSONStore.save(alignmentRecord, key: todayKey)
    }

    func loadAllData() {
        lifeGoals = LocalJSONStore.load([LifeGoal].self, key: "life-goals", defaultValue: [])
        loadReflectionJournal()
        regretItems = LocalJSONStore.load([RegretAvoidanceItem].self, key: "regret-avoidance-items", defaultValue: [])

        let todayKey = "alignment-\(DateFormatter.dateKey(for: Date()))"
        alignmentRecord = LocalJSONStore.loadOptional(LifeAlignmentRecord.self, key: todayKey)

        remainingMomentItems = LocalJSONStore.load(
            [RemainingMomentItem].self,
            key: "remaining-moment-items",
            defaultValue: RemainingMomentItem.defaults
        )
        if RemainingMomentItem.migrateLegacyParentDependency(&remainingMomentItems) {
            saveRemainingMomentItems()
        }
        reloadRemainingMomentRecords()
    }

    func reloadRemainingMomentRecords() {
        remainingMomentRecords = LocalJSONStore.load(
            [RemainingMomentRecord].self,
            key: "remaining-moment-records",
            defaultValue: []
        )
    }
}

// MARK: - Life Remaining Ring

private struct LifeRemainingRing: View {
    let percent: Double

    private var percentInt: Int {
        Int((percent * 100).rounded())
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 10)

            Circle()
                .trim(from: 0, to: min(1, max(0, percent)))
                .stroke(
                    LinearGradient(
                        colors: [LifeTheme.warm, LifeTheme.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: percent)

            VStack(spacing: 4) {
                Text("人生剩餘")
                    .font(.caption2)
                    .foregroundStyle(LifeTheme.textSecondary)
                Text("還有 \(percentInt)%")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(LifeTheme.textPrimary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Add Goal Sheet - 修改内容
struct AddGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var note = ""
    @State private var progress: Double = 0

    let onSave: (LifeGoal) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section("目標") {
                    TextField("目標名稱", text: $title)
                    TextField("備註", text: $note, axis: .vertical)
                    Slider(value: $progress, in: 0...1)
                }
            }
            .navigationTitle("新增目標")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        let goal = LifeGoal(
                            title: title,
                            note: note,
                            progress: progress,
                            isCompleted: false,
                            createdAt: Date()
                        )
                        onSave(goal)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - Add Regret Sheet - 修改内容
struct AddRegretSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""

    let onSave: (RegretAvoidanceItem) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section("80歲的你會後悔什麼？") {
                    TextField("輸入重要的事", text: $title)
                }
            }
            .navigationTitle("新增項目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        let item = RegretAvoidanceItem(
                            title: title,
                            status: .notStarted,
                            createdAt: Date()
                        )
                        onSave(item)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - Date Formatter Extension - 修改内容
extension DateFormatter {
    static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

#Preview {
    let store = LifeStore()
    return NavigationStack {
        CountdownView()
            .environmentObject(store)
    }
}
