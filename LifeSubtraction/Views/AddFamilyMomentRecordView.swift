import SwiftUI

// 修改内容 — 新增相處記錄表單
struct AddFamilyMomentRecordView: View {
    @Environment(\.dismiss) private var dismiss

    let member: FamilyMember
    let onSave: (FamilyMomentRecord) -> Void

    @State private var type: FamilyMomentType = .visit
    @State private var date = Date()
    @State private var note = ""

    var body: some View {
        NavigationView {
            Form {
                Section("記錄類型") {
                    Picker("類型", selection: $type) {
                        ForEach(FamilyMomentType.allCases) { t in
                            Label(t.displayName, systemImage: t.iconName).tag(t)
                        }
                    }
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                }

                Section("備註") {
                    TextField("例如：一起吃晚餐、聊了很久", text: $note, axis: .vertical)
                }
            }
            .navigationTitle("新增相處記錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") { save() }
                }
            }
        }
    }

    func save() {
        let record = FamilyMomentRecord(
            familyMemberId: member.id,
            type: type,
            date: date,
            note: note,
            createdAt: Date()
        )
        onSave(record)
        dismiss()
    }
}
