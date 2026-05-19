import SwiftUI

// 修改内容
// 為某個 Moment 新增一次紀錄。

struct AddRemainingMomentRecordView: View {
    @Environment(\.dismiss) private var dismiss

    let item: RemainingMomentItem
    let onSave: (RemainingMomentRecord) -> Void

    @State private var date = Date()
    @State private var note = ""

    var body: some View {
        NavigationView {
            ZStack {
                LifeTheme.subtleBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {

                        VStack(alignment: .leading, spacing: 6) {
                            Text("為「\(item.title)」新增一次")
                                .font(.headline)
                                .foregroundStyle(LifeTheme.textPrimary)
                            Text("把握每一次值得的時刻。")
                                .font(.subheadline)
                                .foregroundStyle(LifeTheme.textSecondary)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("日期")
                                .font(.caption).fontWeight(.medium)
                                .foregroundStyle(LifeTheme.textTertiary)

                            HStack {
                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .labelsHidden()
                                    .environment(\.locale, Locale(identifier: "zh_TW"))
                                Spacer()
                            }
                            .padding(14)
                            .background(fieldBackground)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("備註（選填）")
                                .font(.caption).fontWeight(.medium)
                                .foregroundStyle(LifeTheme.textTertiary)

                            TextField("和誰、在哪裡、感覺如何…", text: $note, axis: .vertical)
                                .lineLimit(3...6)
                                .padding(14)
                                .background(fieldBackground)
                                .foregroundStyle(LifeTheme.textPrimary)
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("新增記錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(LifeTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        onSave(RemainingMomentRecord(itemId: item.id, date: date, note: note))
                        dismiss()
                    }
                    .foregroundStyle(LifeTheme.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(LifeTheme.glassFill)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
            )
    }
}
