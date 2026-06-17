import SwiftUI

/// 新增或調整人生目標：標題、分類、可編輯的進度步驟。
struct GoalSetupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var category: GoalCategory
    @State private var stages: [GoalStage]
    @State private var notes: String
    @State private var detailSelections: [GoalDetailSelection]

    let catalogId: String?
    let onSave: (LifeGoal) -> Void

    init(
        title: String = "",
        category: GoalCategory = .growth,
        catalogId: String? = nil,
        stages: [GoalStage]? = nil,
        notes: String = "",
        onSave: @escaping (LifeGoal) -> Void
    ) {
        _title = State(initialValue: title)
        _category = State(initialValue: category)
        _stages = State(initialValue: stages ?? GoalStageGenerator.makeStages(
            catalogId: catalogId,
            title: title,
            category: category
        ))
        _notes = State(initialValue: notes)
        _detailSelections = State(initialValue: GoalDetailOptions.defaultSelections(for: catalogId))
        self.catalogId = catalogId
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("事件名稱")
                            .font(.headline)
                            .foregroundStyle(LifeTheme.textPrimary)
                        TextField("例如：帶父母旅行一次", text: $title)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
                            .foregroundStyle(LifeTheme.textPrimary)
                    }
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("分類")
                            .font(.headline)
                            .foregroundStyle(LifeTheme.textPrimary)
                        Picker("分類", selection: $category) {
                            ForEach(GoalCategory.allCases) { cat in
                                Text(cat.displayName).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(LifeTheme.accent)
                    }
                    .cardStyle()

                    GoalDetailConfiguratorView(
                        catalogId: catalogId,
                        selections: $detailSelections,
                        isEditable: true
                    ) {}

                    GoalStagesEditor(stages: $stages) {
                        // 使用者手動編輯中，不自動覆寫
                    }
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("備註")
                            .font(.headline)
                            .foregroundStyle(LifeTheme.textPrimary)
                        TextField("書名、地點、想記下的事…", text: $notes, axis: .vertical)
                            .lineLimit(2...5)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
                            .foregroundStyle(LifeTheme.textPrimary)
                    }
                    .cardStyle()

                    SecondaryButton("依標題重新生成步驟", icon: "arrow.clockwise") {
                        stages = GoalStageGenerator.makeStages(
                            catalogId: catalogId,
                            title: title,
                            category: category
                        )
                    }
                }
                .padding()
            }
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("設定人生事件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let goal = LifeGoal(
            title: trimmed,
            category: category,
            notes: notes,
            stages: stages,
            catalogId: catalogId,
            detailSelections: detailSelections
        )
        onSave(goal)
        dismiss()
    }
}
