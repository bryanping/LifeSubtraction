import SwiftUI

struct ValuesView: View {
    @EnvironmentObject var store: LifeStore

    @State private var showAddValueSheet = false
    @State private var newName = ""
    @State private var newIcon = "star"

    @State private var lifeGoals: [LifeGoal] = []
    @State private var regretItems: [RegretAvoidanceItem] = []
    @State private var alignmentRecord: LifeAlignmentRecord?
    @State private var showingAddGoal = false
    @State private var showingAddRegret = false

    private let iconOptions = [
        "star", "heart", "leaf", "bolt", "flame", "person.2",
        "house", "book", "music.note", "paintbrush", "sportscourt", "globe"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    valuesSection
                    actionSection
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
                        Button { showAddValueSheet = true } label: {
                            Label("新增價值觀", systemImage: "heart")
                        }
                        Button { showingAddGoal = true } label: {
                            Label("新增行動", systemImage: "target")
                        }
                        Button { showingAddRegret = true } label: {
                            Label("新增避免遺憾", systemImage: "lightbulb")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(LifeTheme.accent)
                    }
                }
            }
            .onAppear { loadAllData() }
            .sheet(isPresented: $showAddValueSheet) { addValueSheet }
            .sheet(isPresented: $showingAddGoal) {
                AddGoalSheet { goal in
                    lifeGoals.append(goal)
                    saveGoals()
                }
            }
            .sheet(isPresented: $showingAddRegret) {
                AddRegretSheet { item in
                    regretItems.append(item)
                    saveRegretItems()
                }
            }
        }
    }

    // MARK: - 價值觀

    var valuesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("價值觀", subtitle: "什麼對我最重要")

            ForEach($store.values) { $value in
                ValueRow(value: $value) { id in
                    store.values.removeAll { $0.id == id }
                }
            }
        }
    }

    // MARK: - 行動清單

    var actionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("行動清單", subtitle: "我要把時間投入哪裡")

            if !lifeGoals.isEmpty {
                actionGroup(title: "人生目標") {
                    ForEach($lifeGoals) { $goal in
                        goalRow($goal)
                    }
                }
            }

            actionGroup(title: "避免遺憾") {
                if regretItems.isEmpty {
                    Text("80 歲的你，會後悔什麼沒做？")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textTertiary)
                } else {
                    ForEach(regretItems) { item in
                        regretRow(item)
                    }
                }
            }

            actionGroup(title: "人生對齊") {
                Text("今天的行動，有接近你想成為的人嗎？")
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textTertiary)

                ForEach(LifeAlignmentLevel.allCases) { level in
                    Button { selectAlignment(level) } label: {
                        HStack {
                            Text(level.displayName)
                                .foregroundStyle(
                                    alignmentRecord?.level == level
                                        ? Color.white
                                        : LifeTheme.textPrimary
                                )
                            Spacer()
                            if alignmentRecord?.level == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(12)
                        .background(
                            alignmentRecord?.level == level
                                ? AnyShapeStyle(LifeTheme.heroGradient)
                                : AnyShapeStyle(LifeTheme.glassFill)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(LifeTheme.textPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)
        }
    }

    func actionGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(LifeTheme.textSecondary)
            content()
        }
        .cardStyle()
    }

    func goalRow(_ goal: Binding<LifeGoal>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.wrappedValue.title)
                    .font(.subheadline)
                    .foregroundStyle(goal.wrappedValue.isCompleted ? LifeTheme.textTertiary : LifeTheme.textPrimary)
                    .strikethrough(goal.wrappedValue.isCompleted)
                Spacer()
                Button {
                    goal.wrappedValue.isCompleted.toggle()
                    saveGoals()
                } label: {
                    Image(systemName: goal.wrappedValue.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(goal.wrappedValue.isCompleted ? .green : LifeTheme.textTertiary)
                }
            }
            Slider(value: goal.progress, in: 0...1) { _ in saveGoals() }
                .tint(LifeTheme.accent)
        }
    }

    func regretRow(_ item: RegretAvoidanceItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textPrimary)
                Text(item.status.displayName)
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textTertiary)
            }
            Spacer()
        }
    }

    var addValueSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("例如：家人、健康、自由", text: $newName)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(LifeTheme.glassFill))
                        .foregroundStyle(LifeTheme.textPrimary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Image(systemName: icon)
                                .foregroundStyle(newIcon == icon ? LifeTheme.accent : LifeTheme.textTertiary)
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(newIcon == icon ? LifeTheme.accentSoft : Color.white.opacity(0.04))
                                )
                                .onTapGesture { newIcon = icon }
                        }
                    }
                }
                .padding()
            }
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("新增價值觀")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showAddValueSheet = false; newName = "" }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("加入") {
                        guard !newName.isEmpty else { return }
                        store.values.append(LifeValue(name: newName, icon: newIcon))
                        showAddValueSheet = false
                        newName = ""
                        newIcon = "star"
                    }
                }
            }
        }
    }

    func loadAllData() {
        lifeGoals = LocalJSONStore.load([LifeGoal].self, key: StorageKey.lifeGoals, defaultValue: [])
        regretItems = LocalJSONStore.load([RegretAvoidanceItem].self, key: StorageKey.regretItems, defaultValue: [])
        let todayKey = StorageKey.alignment()
        alignmentRecord = LocalJSONStore.loadOptional(LifeAlignmentRecord.self, key: todayKey)
    }

    func saveGoals() {
        LocalJSONStore.save(lifeGoals, key: StorageKey.lifeGoals)
    }

    func saveRegretItems() {
        LocalJSONStore.save(regretItems, key: StorageKey.regretItems)
    }

    func selectAlignment(_ level: LifeAlignmentLevel) {
        alignmentRecord = LifeAlignmentRecord(date: Date(), level: level)
        LocalJSONStore.save(alignmentRecord, key: StorageKey.alignment())
    }
}

// MARK: - ValueRow

struct ValueRow: View {
    @Binding var value: LifeValue
    var onDelete: (UUID) -> Void
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: value.icon)
                    .foregroundStyle(LifeTheme.accent)
                    .frame(width: 36, height: 36)
                    .background(LifeTheme.accentSoft, in: Circle())
                Text(value.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(LifeTheme.textPrimary)
                Spacer()
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textTertiary)
            }
            .contentShape(Rectangle())
            .onTapGesture { withAnimation { expanded.toggle() } }

            if expanded {
                TextField("為什麼這對你重要？", text: $value.reflection, axis: .vertical)
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textSecondary)
                    .lineLimit(2...5)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))

                HStack {
                    Spacer()
                    Button(role: .destructive) { onDelete(value.id) } label: {
                        Label("刪除", systemImage: "trash").font(.caption)
                    }
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Sheets

struct AddGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var note = ""
    @State private var progress: Double = 0
    let onSave: (LifeGoal) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("目標") {
                    TextField("例如：每月陪父母一次", text: $title)
                    TextField("備註", text: $note, axis: .vertical)
                    Slider(value: $progress, in: 0...1)
                }
            }
            .navigationTitle("新增行動")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        onSave(LifeGoal(title: title, note: note, progress: progress))
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct AddRegretSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    let onSave: (RegretAvoidanceItem) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("80 歲的你會後悔什麼？") {
                    TextField("輸入重要的事", text: $title)
                }
            }
            .navigationTitle("避免遺憾")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        onSave(RegretAvoidanceItem(title: title, status: .notStarted, createdAt: Date()))
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ValuesView()
        .environmentObject(LifeStore())
}
