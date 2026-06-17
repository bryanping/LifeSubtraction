import SwiftUI

struct GoalCatalogView: View {
    @Environment(\.dismiss) private var dismiss

    let goals: [LifeGoal]
    let onAdopt: (GoalCatalogEntry) -> Void

    @State private var selectedCategory: GoalCategory?
    @State private var searchText = ""
    @State private var sortMode: GoalCatalogStats.SortMode = .popular

    private var filtered: [GoalCatalogEntry] {
        var list = GoalCatalog.all
        if let selectedCategory {
            list = list.filter { $0.category == selectedCategory }
        }
        if !searchText.isEmpty {
            list = list.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        return GoalCatalogStats.sorted(list, mode: sortMode, goals: goals)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sortPicker
                    categoryChips

                    Text("共 \(GoalCatalog.all.count) 個人生事件靈感")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textTertiary)
                        .padding(.horizontal, 4)

                    LazyVStack(spacing: 10) {
                        ForEach(filtered) { entry in
                            catalogRow(entry)
                        }
                    }
                }
                .padding()
            }
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("探索人生事件")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "搜尋想完成的事")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉") { dismiss() }
                }
            }
        }
    }

    private var sortPicker: some View {
        Picker("排序", selection: $sortMode) {
            ForEach(GoalCatalogStats.SortMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chipButton(title: "全部", category: nil)
                ForEach(GoalCategory.allCases) { category in
                    chipButton(title: category.displayName, category: category)
                }
            }
        }
    }

    func chipButton(title: String, category: GoalCategory?) -> some View {
        let selected = selectedCategory == category
        return Button {
            withAnimation(.snappy) { selectedCategory = category }
        } label: {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(selected ? Color.white : LifeTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(selected ? AnyShapeStyle(LifeTheme.heroGradient) : AnyShapeStyle(LifeTheme.glassFill))
                )
        }
        .buttonStyle(.plain)
    }

    func catalogRow(_ entry: GoalCatalogEntry) -> some View {
        let myCount = GoalCatalogStats.userCompletedCount(catalogId: entry.id, goals: goals)
        let globalCount = GoalCatalogStats.globalAdoptionCount(catalogId: entry.id)

        return HStack(spacing: 12) {
            Image(systemName: entry.category.iconName)
                .foregroundStyle(LifeTheme.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(LifeTheme.textPrimary)
                Text(entry.category.displayName)
                    .font(.caption2)
                    .foregroundStyle(LifeTheme.textTertiary)
                HStack(spacing: 8) {
                    Text("你已完成 \(myCount) 次")
                    Text("·")
                    Text("已被添加 \(globalCount) 次")
                }
                .font(.caption2)
                .foregroundStyle(LifeTheme.textQuaternary)
            }

            Spacer()

            Button("加入") {
                onAdopt(entry)
                dismiss()
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(LifeTheme.accent)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(LifeTheme.glassFill))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(LifeTheme.glassBorder, lineWidth: 0.5))
    }
}
