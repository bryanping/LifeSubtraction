import SwiftUI

// MARK: - AddTaskView
// 快速新增人生小任務。設計原則：最少步驟，一個 TextField 就能完成新增。

struct AddTaskView: View {
    let onAdd: (LifeTask) -> Void

    @State private var title = ""
    @State private var selectedCategory: GoalCategory = .experience
    @State private var selectedTime: EstimatedTime? = nil
    @State private var isStarred = false
    @Environment(\.dismiss) var dismiss

    // 快速範本
    private let templates = [
        ("和父母吃頓飯", GoalCategory.family),
        ("去一次海邊", GoalCategory.experience),
        ("完成一本書", GoalCategory.growth),
        ("整理一次房間", GoalCategory.creation),
        ("拍一組家庭照片", GoalCategory.family),
        ("學會一道菜", GoalCategory.growth),
        ("寫一封信給未來的自己", GoalCategory.creation),
        ("去一個沒去過的地方", GoalCategory.experience),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 主輸入
                    titleSection

                    // 快速範本
                    templateSection

                    // 類別
                    categorySection

                    // 預估時間
                    timeSection

                    // 釘選
                    starSection

                    Spacer(minLength: 20)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("加入待辦")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(LifeTheme.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("加入") { addTask() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(
                            title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? LifeTheme.textTertiary
                                : LifeTheme.accent
                        )
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Sections

    var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("你想做什麼？")
                .font(.caption)
                .foregroundStyle(LifeTheme.textTertiary)
            TextField("例如：和媽媽吃頓飯", text: $title, axis: .vertical)
                .lineLimit(1...3)
                .font(.title3)
                .foregroundStyle(LifeTheme.textPrimary)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LifeTheme.glassFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
                )
        }
    }

    var templateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("快速範本")
                .font(.caption)
                .foregroundStyle(LifeTheme.textTertiary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(templates, id: \.0) { text, category in
                    Button {
                        title = text
                        selectedCategory = category
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.iconName)
                                .font(.caption2)
                            Text(text)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundStyle(
                            title == text ? LifeTheme.accent : LifeTheme.textSecondary
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(title == text ? LifeTheme.accentSoft : LifeTheme.glassFill)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    title == text ? LifeTheme.accent.opacity(0.3) : LifeTheme.glassBorder,
                                    lineWidth: 0.5
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("類別")
                .font(.caption)
                .foregroundStyle(LifeTheme.textTertiary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(GoalCategory.allCases) { cat in
                        Button {
                            selectedCategory = cat
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: cat.iconName)
                                    .font(.caption2)
                                Text(cat.displayName)
                                    .font(.caption)
                            }
                            .foregroundStyle(
                                selectedCategory == cat ? LifeTheme.accent : LifeTheme.textSecondary
                            )
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == cat ? LifeTheme.accentSoft : LifeTheme.glassFill)
                            )
                            .overlay(
                                Capsule().stroke(
                                    selectedCategory == cat ? LifeTheme.accent.opacity(0.4) : LifeTheme.glassBorder,
                                    lineWidth: 0.5
                                )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    var timeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("大概需要多少時間？（可選）")
                .font(.caption)
                .foregroundStyle(LifeTheme.textTertiary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EstimatedTime.allCases) { time in
                        Button {
                            selectedTime = selectedTime == time ? nil : time
                        } label: {
                            Text(time.label)
                                .font(.caption)
                                .foregroundStyle(
                                    selectedTime == time ? LifeTheme.accent : LifeTheme.textSecondary
                                )
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(selectedTime == time ? LifeTheme.accentSoft : LifeTheme.glassFill)
                                )
                                .overlay(
                                    Capsule().stroke(
                                        selectedTime == time ? LifeTheme.accent.opacity(0.4) : LifeTheme.glassBorder,
                                        lineWidth: 0.5
                                    )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    var starSection: some View {
        Button {
            isStarred.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isStarred ? "star.fill" : "star")
                    .foregroundStyle(isStarred ? LifeTheme.warm : LifeTheme.textTertiary)
                Text("釘選到優先推薦")
                    .font(.subheadline)
                    .foregroundStyle(isStarred ? LifeTheme.textPrimary : LifeTheme.textSecondary)
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LifeTheme.glassFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Action

    func addTask() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let task = LifeTask(
            title: trimmed,
            category: selectedCategory,
            estimatedMinutes: selectedTime?.rawValue,
            isStarred: isStarred
        )
        onAdd(task)
        dismiss()
    }
}

#Preview {
    AddTaskView { _ in }
}
