import SwiftUI

/// 點選細項按鈕後開啟：從選項庫挑選或填寫自訂內容。
struct GoalDetailFieldPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let catalogId: String?
    let field: GoalDetailFieldSpec
    let selections: [GoalDetailSelection]
    @Binding var selectedValue: String
    /// value, sharePreset, fromCustom, saveToLibrary
    let onConfirm: (String, Bool, Bool, Bool) -> Void

    @State private var mode: PickMode = .library
    @State private var customText = ""
    @State private var saveToLibrary = true
    @State private var sharePreset = false
    @State private var librarySelection = ""

    private enum PickMode: String, CaseIterable, Identifiable {
        case library = "選項庫"
        case custom = "自訂"

        var id: String { rawValue }
    }

    private var libraryOptions: [GoalDetailOptionItem] {
        GoalDetailOptions.allOptions(
            for: field,
            catalogId: catalogId,
            selections: selections
        )
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Picker("方式", selection: $mode) {
                    ForEach(PickMode.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                switch mode {
                case .library:
                    libraryContent
                case .custom:
                    customContent
                }

                Spacer(minLength: 0)
            }
            .padding()
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle(field.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("確定") { confirm() }
                        .disabled(!canConfirm)
                }
            }
            .onAppear {
                librarySelection = selectedValue
                customText = selectedValue
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var libraryContent: some View {
        Group {
            if libraryOptions.isEmpty {
                VStack(spacing: 10) {
                    Text("選項庫尚無內容")
                        .font(.subheadline)
                        .foregroundStyle(LifeTheme.textSecondary)
                    Text("可切換到「自訂」填寫，並選擇是否共享給其他使用者")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(libraryOptions) { item in
                            libraryRow(item)
                        }
                    }
                }
            }
        }
    }

    private func libraryRow(_ item: GoalDetailOptionItem) -> some View {
        let selected = librarySelection == item.value
        return Button {
            librarySelection = item.value
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.value)
                        .font(.subheadline)
                        .foregroundStyle(LifeTheme.textPrimary)
                    if item.isShared {
                        Text("全平台預選")
                            .font(.caption2)
                            .foregroundStyle(LifeTheme.accent.opacity(0.85))
                    } else if item.isLocal {
                        Text("我的預選")
                            .font(.caption2)
                            .foregroundStyle(LifeTheme.textTertiary)
                    }
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? LifeTheme.accent : LifeTheme.textQuaternary)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(LifeTheme.glassFill))
        }
        .buttonStyle(.plain)
    }

    private var customContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField(field.placeholder, text: $customText)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
                .foregroundStyle(LifeTheme.textPrimary)

            Toggle(isOn: $saveToLibrary) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("加入選項庫")
                        .font(.subheadline)
                        .foregroundStyle(LifeTheme.textPrimary)
                    Text("儲存後下次可快速選取")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textTertiary)
                }
            }
            .tint(LifeTheme.accent)

            if saveToLibrary {
                Toggle(isOn: $sharePreset) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("共享此預選")
                            .font(.subheadline)
                            .foregroundStyle(LifeTheme.textPrimary)
                        Text("讓所有使用者都可以在選項庫看到（可取消）")
                            .font(.caption)
                            .foregroundStyle(LifeTheme.textTertiary)
                    }
                }
                .tint(LifeTheme.accent)
            }
        }
    }

    private var canConfirm: Bool {
        switch mode {
        case .library:
            return !librarySelection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .custom:
            return !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func confirm() {
        let value: String
        let shouldShare: Bool
        let shouldSave: Bool
        switch mode {
        case .library:
            value = librarySelection.trimmingCharacters(in: .whitespacesAndNewlines)
            shouldShare = false
            shouldSave = false
        case .custom:
            value = customText.trimmingCharacters(in: .whitespacesAndNewlines)
            shouldShare = sharePreset
            shouldSave = saveToLibrary
        }
        guard !value.isEmpty else { return }
        selectedValue = value
        onConfirm(value, shouldShare, mode == .custom, shouldSave)
        dismiss()
    }
}
