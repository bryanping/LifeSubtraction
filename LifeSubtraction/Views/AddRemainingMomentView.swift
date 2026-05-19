import SwiftUI

// 修改内容
// 新增「你還有幾次？」自定項目。

struct AddRemainingMomentView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var unit = "次"
    @State private var iconName = "star.fill"
    @State private var frequency: RemainingMomentFrequency = .yearly
    @State private var customTimesPerYearText = ""
    @State private var dependsOn: RemainingMomentDependency = .selfLife   // 修改内容

    let iconOptions = [
        "star.fill", "heart.fill", "leaf.fill", "bolt.fill", "flame.fill",
        "house.fill", "person.2.fill", "book.fill", "music.note", "paintbrush.fill",
        "sportscourt.fill", "globe", "airplane", "sparkles", "sun.max.fill",
        "moon.fill", "cup.and.saucer.fill", "fork.knife", "camera.fill", "film.fill"
    ]

    let onSave: (RemainingMomentItem) -> Void

    var body: some View {
        NavigationView {
            ZStack {
                LifeTheme.subtleBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {

                        section("名稱") {
                            TextField("例如：與好友見面、看演唱會", text: $title)
                                .textFieldStyle(.plain)
                                .padding(14)
                                .background(fieldBackground)
                                .foregroundStyle(LifeTheme.textPrimary)
                        }

                        section("單位") {
                            TextField("例如：次、本、場", text: $unit)
                                .textFieldStyle(.plain)
                                .padding(14)
                                .background(fieldBackground)
                                .foregroundStyle(LifeTheme.textPrimary)
                        }

                        section("圖示") {
                            iconPicker
                        }

                        section("頻率") {
                            VStack(spacing: 0) {
                                Picker("Frequency", selection: $frequency) {
                                    ForEach(RemainingMomentFrequency.allCases) { f in
                                        Text(f.displayName).tag(f)
                                    }
                                }
                                .pickerStyle(.segmented)

                                if frequency == .custom {
                                    HStack {
                                        Text("一年大約幾次")
                                            .foregroundStyle(LifeTheme.textSecondary)
                                            .font(.subheadline)
                                        Spacer()
                                        TextField("0", text: $customTimesPerYearText)
                                            .keyboardType(.numberPad)
                                            .multilineTextAlignment(.trailing)
                                            .foregroundStyle(LifeTheme.textPrimary)
                                            .frame(width: 80)
                                    }
                                    .padding(14)
                                    .background(fieldBackground)
                                    .padding(.top, 8)
                                }
                            }
                        }

                        // 修改内容 — 依賴對象 picker：決定剩餘年數要套自己 or 父母
                        section("依賴對象") {
                            VStack(alignment: .leading, spacing: 8) {
                                Picker("Dependency", selection: $dependsOn) {
                                    ForEach(RemainingMomentDependency.allCases) { d in
                                        Text(d.displayName).tag(d)
                                    }
                                }
                                .pickerStyle(.segmented)

                                Text(dependsOn.hint)
                                    .font(.caption)
                                    .foregroundStyle(LifeTheme.textTertiary)
                            }
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("新增項目")
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
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Components  // 修改内容

    func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption).fontWeight(.medium)
                .foregroundStyle(LifeTheme.textTertiary)
            content()
        }
    }

    var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(LifeTheme.glassFill)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
            )
    }

    var iconPicker: some View {
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

    // MARK: - Save  // 修改内容

    func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let item = RemainingMomentItem(
            title: trimmed,
            iconName: iconName,
            unit: unit.isEmpty ? "次" : unit,
            frequency: frequency,
            customTimesPerYear: Int(customTimesPerYearText),
            dependsOn: dependsOn                        // 修改内容
        )
        onSave(item)
        dismiss()
    }
}
