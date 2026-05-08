import SwiftUI

// 修改内容 — 新增家人表單
struct AddFamilyMemberView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var relation: FamilyRelation = .father
    @State private var currentAgeText = ""
    @State private var lifeExpectancyText = "80"
    @State private var note = ""

    let onSave: (FamilyMember) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section("基本資料") {
                    TextField("名字或稱呼", text: $name)

                    Picker("關係", selection: $relation) {
                        ForEach(FamilyRelation.allCases) { r in
                            Text(r.displayName).tag(r)
                        }
                    }

                    TextField("目前年齡", text: $currentAgeText)
                        .keyboardType(.numberPad)

                    TextField("預期壽命", text: $lifeExpectancyText)
                        .keyboardType(.numberPad)
                }

                Section("備註") {
                    TextField("例如：希望每月見一次", text: $note, axis: .vertical)
                }

                Section {
                    Text("預期壽命只是估算，用來幫助你更珍惜相處機會。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("新增家人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Int(currentAgeText) != nil &&
        Int(lifeExpectancyText) != nil
    }

    func save() {
        guard let currentAge = Int(currentAgeText),
              let lifeExpectancy = Int(lifeExpectancyText) else { return }

        let member = FamilyMember(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            relation: relation,
            currentAge: currentAge,
            lifeExpectancy: lifeExpectancy,
            note: note,
            createdAt: Date(),
            isArchived: false
        )
        onSave(member)
        dismiss()
    }
}
