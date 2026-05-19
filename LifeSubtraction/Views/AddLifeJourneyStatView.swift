import SwiftUI

struct AddLifeJourneyStatView: View {
    @Environment(\.dismiss) private var dismiss

    let existing: LifeJourneyStatItem?
    let onSave: (LifeJourneyStatItem) -> Void

    @State private var title = ""
    @State private var unit = "次"
    @State private var iconName = "star.fill"
    @State private var metricKind: LifeJourneyStatMetricKind = .daysLived
    @State private var manualValueText = ""

    private let iconOptions = [
        "star.fill", "heart.fill", "leaf.fill", "bolt.fill", "flame.fill",
        "house.fill", "person.2.fill", "book.fill", "music.note", "paintbrush.fill",
        "sportscourt.fill", "globe", "airplane", "sparkles", "sun.max.fill",
        "moon.fill", "cup.and.saucer.fill", "fork.knife", "camera.fill", "film.fill",
        "calendar", "gift.fill", "clock.fill", "figure.walk", "mountain.2.fill"
    ]

    init(existing: LifeJourneyStatItem? = nil, onSave: @escaping (LifeJourneyStatItem) -> Void) {
        self.existing = existing
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LifeTheme.subtleBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        section("顯示名稱") {
                            TextField("例如：出國旅行、讀過的書", text: $title)
                                .textFieldStyle(.plain)
                                .padding(14)
                                .background(fieldBackground)
                                .foregroundStyle(LifeTheme.textPrimary)
                        }

                        section("單位") {
                            TextField("例如：天、次、本", text: $unit)
                                .textFieldStyle(.plain)
                                .padding(14)
                                .background(fieldBackground)
                                .foregroundStyle(LifeTheme.textPrimary)
                        }

                        section("圖示") {
                            iconPicker
                        }

                        section("數據來源") {
                            VStack(alignment: .leading, spacing: 8) {
                                Picker("Metric", selection: $metricKind) {
                                    ForEach(LifeJourneyStatMetricKind.allCases) { kind in
                                        Text(kind.displayName).tag(kind)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(LifeTheme.accent)

                                Text(metricKind.hint)
                                    .font(.caption)
                                    .foregroundStyle(LifeTheme.textTertiary)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(fieldBackground)
                        }

                        if metricKind == .manual {
                            section("目前數值") {
                                TextField("0", text: $manualValueText)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.plain)
                                    .padding(14)
                                    .background(fieldBackground)
                                    .foregroundStyle(LifeTheme.textPrimary)
                            }
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .scrollContentBackground(.hidden)
            }
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
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: applyExisting)
            .onChange(of: metricKind) { _, newValue in
                if existing == nil, unit == LifeJourneyStatMetricKind.daysLived.defaultUnit
                    || LifeJourneyStatMetricKind.allCases.map(\.defaultUnit).contains(unit) {
                    unit = newValue.defaultUnit
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func applyExisting() {
        guard let existing else { return }
        title = existing.title
        unit = existing.unit
        iconName = existing.iconName
        metricKind = existing.metricKind
        if let manualValue = existing.manualValue {
            manualValueText = "\(manualValue)"
        }
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
        guard !trimmed.isEmpty else { return }

        let manualValue = metricKind == .manual ? Int(manualValueText) : nil
        let resolvedUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? metricKind.defaultUnit
            : unit

        let item = LifeJourneyStatItem(
            id: existing?.id ?? UUID(),
            title: trimmed,
            iconName: iconName,
            metricKind: metricKind,
            unit: resolvedUnit,
            manualValue: manualValue,
            createdAt: existing?.createdAt ?? Date(),
            isArchived: existing?.isArchived ?? false
        )
        onSave(item)
        dismiss()
    }
}
