import SwiftUI

struct AddLifeJourneyStatView: View {
    @Environment(\.dismiss) private var dismiss

    let existing: LifeJourneyStatItem?
    let existingItems: [LifeJourneyStatItem]
    let onSave: (LifeJourneyStatItem) -> Void

    @State private var title = ""
    @State private var unit = "次"
    @State private var iconName = "star.fill"
    @State private var baselineText = "0"

    private let iconOptions = [
        "star.fill", "heart.fill", "leaf.fill", "bolt.fill", "flame.fill",
        "house.fill", "person.2.fill", "book.fill", "music.note", "paintbrush.fill",
        "sportscourt.fill", "globe", "airplane", "sparkles", "figure.run",
        "camera.fill", "film.fill", "figure.walk", "mountain.2.fill"
    ]

    init(
        existing: LifeJourneyStatItem? = nil,
        existingItems: [LifeJourneyStatItem] = [],
        onSave: @escaping (LifeJourneyStatItem) -> Void
    ) {
        self.existing = existing
        self.existingItems = existingItems
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    section("顯示名稱") {
                        TextField("例如：完成作品、運動", text: $title)
                            .padding(14)
                            .background(fieldBackground)
                            .foregroundStyle(LifeTheme.textPrimary)
                    }

                    section("單位") {
                        TextField("例如：次、本、場", text: $unit)
                            .padding(14)
                            .background(fieldBackground)
                            .foregroundStyle(LifeTheme.textPrimary)
                    }

                    section("過去估算累積") {
                        TextField("0", text: $baselineText)
                            .keyboardType(.numberPad)
                            .padding(14)
                            .background(fieldBackground)
                            .foregroundStyle(LifeTheme.textPrimary)
                        Text("若尚未完成問卷，可手動填入過去大概的累積次數。")
                            .font(.caption)
                            .foregroundStyle(LifeTheme.textTertiary)
                    }

                    section("圖示") { iconPicker }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .scrollContentBackground(.hidden)
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle(existing == nil ? "新增累積" : "編輯累積")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(LifeTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存", action: save)
                        .foregroundStyle(LifeTheme.accent)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: applyExisting)
        }
        .preferredColorScheme(.dark)
    }

    private var canSave: Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if existing == nil {
            return LifeJourneyStatItem.isTitleAvailable(trimmed, among: existingItems)
        }
        let duplicates = existingItems.filter {
            !$0.isArchived && $0.title == trimmed && $0.id != existing?.id
        }
        return duplicates.isEmpty
    }

    private func applyExisting() {
        guard let existing else { return }
        title = existing.title
        unit = existing.unit
        iconName = existing.iconName
        baselineText = "\(existing.baselineEstimate)"
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption).fontWeight(.medium)
                .foregroundStyle(LifeTheme.textTertiary)
            content()
        }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(LifeTheme.glassFill)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
            )
    }

    private var iconPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(iconOptions, id: \.self) { name in
                Image(systemName: name)
                    .font(.title3)
                    .foregroundStyle(iconName == name ? LifeTheme.accent : LifeTheme.textTertiary)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(iconName == name ? LifeTheme.accentSoft : Color.white.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(iconName == name ? LifeTheme.accentMuted : LifeTheme.glassBorder, lineWidth: 0.5)
                    )
                    .onTapGesture { iconName = name }
            }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canSave else { return }

        let item = LifeJourneyStatItem(
            id: existing?.id ?? UUID(),
            title: trimmed,
            iconName: iconName,
            unit: unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "次" : unit,
            baselineEstimate: max(0, Int(baselineText) ?? 0),
            timesPerMonth: existing?.timesPerMonth,
            timesPerYear: existing?.timesPerYear,
            linkedMomentId: existing?.linkedMomentId,
            template: existing?.template,
            createdAt: existing?.createdAt ?? Date(),
            isArchived: existing?.isArchived ?? false
        )
        onSave(item)
        dismiss()
    }
}
