import SwiftUI

struct RemainingMomentDetailView: View {
    let item: RemainingMomentItem
    @Binding var journeyStats: [LifeJourneyStatItem]
    @Binding var journeyRecords: [LifeJourneyStatRecord]

    @EnvironmentObject var store: LifeStore

    @State private var allRecords: [RemainingMomentRecord] = []
    @State private var showingAddRecord = false

    init(
        item: RemainingMomentItem,
        journeyStats: Binding<[LifeJourneyStatItem]>,
        journeyRecords: Binding<[LifeJourneyStatRecord]>
    ) {
        self.item = item
        _journeyStats = journeyStats
        _journeyRecords = journeyRecords
    }

    private var myRecords: [RemainingMomentRecord] {
        allRecords
            .filter { $0.itemId == item.id }
            .sorted(by: { $0.date > $1.date })
    }

    private var linkedStat: LifeJourneyStatItem? {
        journeyStats.first { $0.linkedMomentId == item.id && !$0.isArchived }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                detailHeader
                    .padding(.horizontal)

                Button { showingAddRecord = true } label: {
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
                }
                .padding(.horizontal)

                if let stat = linkedStat {
                    cumulativeSummary(for: stat)
                        .padding(.horizontal)
                }

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
                syncJourneyRecord(from: record)
            }
            .environmentObject(store)
        }
    }

    var detailHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: item.iconName)
                    .foregroundStyle(LifeTheme.accent)
                    .frame(width: 36, height: 36)
                    .background(LifeTheme.accentSoft, in: Circle())

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

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("約剩")
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textSecondary)
                Text("\(estimatedRemainingCount.formatted())")
                    .font(.system(size: 56, weight: .light, design: .rounded))
                    .foregroundStyle(LifeTheme.warm)
                Text(item.unit)
                    .font(.title3)
                    .foregroundStyle(LifeTheme.textSecondary)
            }

            Text(item.dependsOn.hint)
                .font(.caption)
                .foregroundStyle(LifeTheme.textTertiary)
        }
        .cardStyle()
    }

    func cumulativeSummary(for stat: LifeJourneyStatItem) -> some View {
        let total = JourneyStatCalculator.totalCount(item: stat, records: journeyRecords)
        let thisMonth = JourneyStatCalculator.thisMonthCount(itemId: stat.id, records: journeyRecords)
        let lastMonth = JourneyStatCalculator.lastMonthCount(itemId: stat.id, records: journeyRecords)

        return VStack(alignment: .leading, spacing: 8) {
            Text("人生累積")
                .font(.headline)
                .foregroundStyle(LifeTheme.textPrimary)
            Text("總累積 \(total.formatted()) \(stat.unit)")
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textPrimary)
            Text("上月 +\(lastMonth) · 本月 +\(thisMonth)")
                .font(.caption)
                .foregroundStyle(LifeTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 16)
    }

    var recordList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("記錄")
                .font(.headline)
                .foregroundStyle(LifeTheme.textPrimary)

            if myRecords.isEmpty {
                Text("新增紀錄後，會同步累積到總覽。")
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textSecondary)
                    .cardStyle(padding: 16)
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
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(LifeTheme.textPrimary)
                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textSecondary)
                }
            }

            Spacer()

            Button(role: .destructive) {
                deleteRecord(record)
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

    var estimatedRemainingCount: Int {
        item.estimatedRemainingOccurrences(store: store, metrics: store.metrics)
    }

    func syncJourneyRecord(from record: RemainingMomentRecord) {
        guard let stat = linkedStat else { return }
        journeyRecords.append(
            LifeJourneyStatRecord(
                statItemId: stat.id,
                date: record.date,
                note: record.note
            )
        )
        LocalJSONStore.save(journeyRecords, key: StorageKey.lifeJourneyStatRecords)
    }

    func deleteRecord(_ record: RemainingMomentRecord) {
        allRecords.removeAll { $0.id == record.id }
        saveRecords()
        if let stat = linkedStat {
            journeyRecords.removeAll {
                $0.statItemId == stat.id &&
                Calendar.current.isDate($0.date, inSameDayAs: record.date) &&
                $0.note == record.note
            }
            LocalJSONStore.save(journeyRecords, key: StorageKey.lifeJourneyStatRecords)
        }
    }

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
