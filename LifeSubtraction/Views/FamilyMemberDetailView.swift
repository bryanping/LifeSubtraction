import SwiftUI

// 修改内容 — 家人詳情頁
struct FamilyMemberDetailView: View {
    let member: FamilyMember

    @State private var records: [FamilyMomentRecord] = []
    @State private var showingAddRecord = false

    var memberRecords: [FamilyMomentRecord] {
        records
            .filter { $0.familyMemberId == member.id }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                headerCard
                    .padding(.horizontal)
                estimateCard
                    .padding(.horizontal)
                recordsCard
                    .padding(.horizontal)
                    .padding(.bottom, 24)
            }
            .padding(.vertical, 8)
        }
        .background(LifeTheme.subtleBackground.ignoresSafeArea())
        .navigationTitle(member.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAddRecord = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(LifeTheme.accent)
                }
            }
        }
        .onAppear { loadRecords() }
        .sheet(isPresented: $showingAddRecord) {
            AddFamilyMomentRecordView(member: member) { record in
                records.append(record)
                saveRecords()
            }
        }
    }

    // 修改内容 — 家人基本資料卡
    var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: member.relation.iconName)
                    .foregroundStyle(LifeTheme.accent)
                Text(member.relation.displayName)
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)
                Spacer()
            }
            Text("\(member.currentAge) 歲 · 預期 \(member.lifeExpectancy) 歲")
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)
            if !member.note.isEmpty {
                Text(member.note)
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textTertiary)
            }
        }
        .cardStyle()
    }

    // 修改内容 — 共同時間估算卡
    var estimateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("你們共同剩下的時間")
                .font(.headline)
                .foregroundStyle(LifeTheme.textPrimary)

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(member.yearsRemaining)")
                    .font(.system(size: 64, weight: .light, design: .rounded))
                    .foregroundStyle(LifeTheme.accent)
                Text("年")
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textSecondary)
            }

            VStack(spacing: 8) {
                estimateRow(title: "每月見一次", value: member.yearsRemaining * 12, unit: "次")
                estimateRow(title: "每週通話一次", value: member.yearsRemaining * 52, unit: "次")
                estimateRow(title: "每年旅行一次", value: member.yearsRemaining, unit: "次")
            }

            Text("這不是你的剩餘時間，而是你們共同剩下的時間。")
                .font(.caption)
                .foregroundStyle(LifeTheme.textTertiary)
                .padding(.top, 4)
        }
        .cardStyle()
    }

    func estimateRow(title: String, value: Int, unit: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)
            Spacer()
            Text("\(value)")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(LifeTheme.textPrimary)
            Text(unit)
                .font(.caption)
                .foregroundStyle(LifeTheme.textTertiary)
        }
    }

    // 修改内容 — 相處記錄卡
    var recordsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("相處記錄")
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)
                Spacer()
                Button {
                    showingAddRecord = true
                } label: {
                    Label("新增", systemImage: "plus")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.accent)
                }
            }

            if memberRecords.isEmpty {
                Text("還沒有記錄。記下一次見面、通話或旅行。")
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(memberRecords) { record in
                        recordRow(record)
                    }
                }
            }
        }
        .cardStyle()
    }

    func recordRow(_ record: FamilyMomentRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: record.type.iconName)
                .foregroundStyle(LifeTheme.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.type.displayName)
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textPrimary)
                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(LifeTheme.textTertiary)
                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textSecondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }

    func loadRecords() {
        records = LocalJSONStore.load(
            [FamilyMomentRecord].self,
            key: AppConstants.Key.familyMomentRecords,
            defaultValue: []
        )
    }

    func saveRecords() {
        LocalJSONStore.save(records, key: AppConstants.Key.familyMomentRecords)
    }
}
