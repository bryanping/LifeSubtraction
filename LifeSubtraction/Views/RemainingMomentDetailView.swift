import SwiftUI

// 修改内容
// Moment 細節頁：剩餘次數、頻率、紀錄列表 + 新增紀錄。
// 修正父母剩餘次數估算：父母類型改用 parentLifeExpectancy - parentAge，不再用自己的剩餘年限限制。

struct RemainingMomentDetailView: View {
    let item: RemainingMomentItem
    @EnvironmentObject var store: LifeStore

    @State private var allRecords: [RemainingMomentRecord] = []
    @State private var showingAddRecord = false

    private var myRecords: [RemainingMomentRecord] {
        allRecords
            .filter { $0.itemId == item.id }
            .sorted(by: { $0.date > $1.date })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                detailHeader
                    .padding(.horizontal)

                Button {
                    showingAddRecord = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("新增一次記錄")
                            .fontWeight(.semibold)
                    }
                    .font(.headline)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(LifeTheme.heroGradient))
                    .shadow(color: LifeTheme.accent.opacity(0.25), radius: 14, y: 6)
                }
                .padding(.horizontal)

                recordList
                    .padding(.horizontal)
                    .padding(.bottom, 32)
            }
            .padding(.vertical, 8)
        }
        .scrollContentBackground(.hidden)
        .background(LifeTheme.subtleBackground.ignoresSafeArea())
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear(perform: loadRecords)
        .sheet(isPresented: $showingAddRecord) {
            AddRemainingMomentRecordView(item: item) { record in
                allRecords.append(record)
                saveRecords()
            }
            .environmentObject(store) // 修改内容
        }
    }

    // MARK: - Header

    var detailHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    Circle()
                        .fill(LifeTheme.accentSoft)
                        .frame(width: 44, height: 44)

                    Image(systemName: item.iconName)
                        .foregroundStyle(LifeTheme.accent)
                }

                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)

                Spacer()

                Text(item.frequency.displayName)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(LifeTheme.accentSoft, in: Capsule())
                    .foregroundStyle(LifeTheme.accent)
            }

            Text("這件事還可能有多少次？")
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(estimatedRemainingCount)")
                    .font(.system(size: 64, weight: .light, design: .rounded))
                    .foregroundStyle(LifeTheme.accent)

                Text(item.unit)
                    .font(.title3)
                    .foregroundStyle(LifeTheme.textSecondary)
            }

            HStack(spacing: 6) {
                Image(systemName: item.dependsOn == .parents ? "person.2.fill" : "person.fill")
                    .font(.caption2)
                    .foregroundStyle(item.dependsOn == .parents ? LifeTheme.warm : LifeTheme.textTertiary)

                Text(item.dependsOn.hint)
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textTertiary)

                if item.dependsOn == .parents {
                    Text("父母剩餘約 \(store.parentYearsRemaining) 年") // 修改内容
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(LifeTheme.warmSoft, in: Capsule())
                        .foregroundStyle(LifeTheme.warm)
                }
            }

            HStack {
                stat(label: "已記錄", value: "\(myRecords.count)")
                Spacer()
                stat(label: "估算總次數", value: "\(estimatedTotal)")
                Spacer()
                stat(label: "剩餘年數", value: "\(remainingYearsForEstimate)")
            }
            .padding(.top, 4)
        }
        .cardStyle()
    }

    func stat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(LifeTheme.textPrimary)

            Text(label)
                .font(.caption2)
                .foregroundStyle(LifeTheme.textTertiary)
        }
    }

    // MARK: - Record list

    var recordList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("記錄")
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)

                Spacer()

                if !myRecords.isEmpty {
                    Text("共 \(myRecords.count) 筆")
                        .font(.caption2)
                        .foregroundStyle(LifeTheme.textTertiary)
                }
            }

            if myRecords.isEmpty {
                Text("還沒有記錄。從上方按鈕新增第一筆吧。")
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(LifeTheme.glassFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
                    )
            } else {
                ForEach(myRecords) { record in
                    recordRow(record)
                }
            }
        }
    }

    func recordRow(_ record: RemainingMomentRecord) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(LifeTheme.accent)
                .frame(width: 8, height: 8)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(formatted(record.date))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(LifeTheme.textPrimary)

                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textSecondary)
                }
            }

            Spacer()

            Button(role: .destructive) {
                allRecords.removeAll { $0.id == record.id }
                saveRecords()
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(Color.red.opacity(0.75))
            }
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

    // MARK: - Computed

    var remainingYearsForEstimate: Int {
        switch item.dependsOn {
        case .selfLife:
            return max(0, store.lifeExpectancy - store.ageYears)

        case .parents:
            // 修改内容
            // 父母類型直接使用 LifeStore 集中計算後的剩餘年數
            return store.parentYearsRemaining
        }
    }

    var estimatedTotal: Int {
        max(0, remainingYearsForEstimate * item.estimatedTimesPerYear())
    }

    var estimatedRemainingCount: Int {
        max(0, estimatedTotal - myRecords.count)
    }

    // MARK: - Persistence

    func loadRecords() {
        allRecords = LocalJSONStore.load(
            [RemainingMomentRecord].self,
            key: StorageKey.remainingMomentRecords,
            defaultValue: []
        )
    }

    func saveRecords() {
        LocalJSONStore.save(allRecords, key: StorageKey.remainingMomentRecords)
    }

    func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "yyyy / MM / dd"
        return formatter.string(from: date)
    }
}
