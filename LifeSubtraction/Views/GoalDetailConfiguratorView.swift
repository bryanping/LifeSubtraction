import SwiftUI

/// 目標細項：以按鈕觸發選項庫或自訂填寫。
struct GoalDetailConfiguratorView: View {
    let catalogId: String?
    @Binding var selections: [GoalDetailSelection]
    var isEditable: Bool = true
    var onUpdate: () -> Void

    @State private var activeField: GoalDetailFieldSpec?

    private var fields: [GoalDetailFieldSpec] {
        GoalDetailOptions.fields(for: catalogId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("細項設定")
                .font(.headline)
                .foregroundStyle(LifeTheme.textPrimary)

            ForEach(fields, id: \.id) { field in
                fieldButton(field)
            }

            if isEditable {
                Text("點選各細項，從選項庫挑選或自訂填寫")
                    .font(.caption2)
                    .foregroundStyle(LifeTheme.textTertiary)
            }
        }
        .cardStyle(padding: 16)
        .onAppear(perform: ensureSelections)
        .sheet(item: $activeField) { field in
            GoalDetailFieldPickerContainer(
                catalogId: catalogId,
                field: field,
                selections: $selections,
                onConfirm: { value, sharePreset, fromCustom, saveToLibrary in
                    guard let index = selections.firstIndex(where: { $0.fieldId == field.id }) else { return }
                    selections[index].selectedValue = value
                    if fromCustom, saveToLibrary {
                        let storeId = catalogId ?? "__generic__"
                        if sharePreset {
                            GoalDetailOptions.addSharedPreset(
                                catalogId: storeId,
                                fieldId: field.id,
                                option: value
                            )
                        } else {
                            GoalDetailOptions.addLocalPreset(
                                catalogId: storeId,
                                fieldId: field.id,
                                option: value
                            )
                        }
                    }
                    if fields.contains(where: { $0.dependsOnFieldId == field.id }) {
                        clearDependentSelections(changedFieldId: field.id)
                    }
                    onUpdate()
                }
            )
        }
    }

    private func fieldButton(_ field: GoalDetailFieldSpec) -> some View {
        let value = selections.first(where: { $0.fieldId == field.id })?.selectedValue ?? ""
        let hasValue = !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let parentId = field.dependsOnFieldId
        let parentUnset = parentId != nil && (
            selections.first(where: { $0.fieldId == parentId })?.selectedValue.isEmpty ?? true
        )

        return Button {
            guard isEditable, !parentUnset else { return }
            activeField = field
        } label: {
            HStack(spacing: 10) {
                Image(systemName: hasValue ? "checkmark.circle.fill" : "circle.dashed")
                    .foregroundStyle(hasValue ? LifeTheme.accent : LifeTheme.textQuaternary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(field.label)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(LifeTheme.textPrimary)
                    if hasValue {
                        Text(value)
                            .font(.caption)
                            .foregroundStyle(LifeTheme.textSecondary)
                            .lineLimit(1)
                    } else if parentUnset, let parentLabel = fields.first(where: { $0.id == parentId })?.label {
                        Text("請先選擇\(parentLabel)")
                            .font(.caption)
                            .foregroundStyle(LifeTheme.textTertiary)
                    } else {
                        Text("點擊選擇")
                            .font(.caption)
                            .foregroundStyle(LifeTheme.textTertiary)
                    }
                }

                Spacer()

                if isEditable && !parentUnset {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(LifeTheme.textQuaternary)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
        }
        .buttonStyle(.plain)
        .disabled(!isEditable || parentUnset)
    }

    private func ensureSelections() {
        for field in fields where !selections.contains(where: { $0.fieldId == field.id }) {
            selections.append(GoalDetailSelection(fieldId: field.id, label: field.label, selectedValue: ""))
        }
    }

    private func clearDependentSelections(changedFieldId: String) {
        let dependentIds = fields
            .filter { $0.dependsOnFieldId == changedFieldId }
            .map(\.id)
        for id in dependentIds {
            if let index = selections.firstIndex(where: { $0.fieldId == id }) {
                selections[index].selectedValue = ""
            }
        }
    }
}

extension GoalDetailFieldSpec: Identifiable {}

private struct GoalDetailFieldPickerContainer: View {
    let catalogId: String?
    let field: GoalDetailFieldSpec
    @Binding var selections: [GoalDetailSelection]
    let onConfirm: (String, Bool, Bool, Bool) -> Void

    var body: some View {
        if let index = selections.firstIndex(where: { $0.fieldId == field.id }) {
            GoalDetailFieldPickerSheet(
                catalogId: catalogId,
                field: field,
                selections: selections,
                selectedValue: $selections[index].selectedValue,
                onConfirm: onConfirm
            )
        }
    }
}
