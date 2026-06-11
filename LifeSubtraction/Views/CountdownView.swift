import SwiftUI

struct CountdownView: View {
    @EnvironmentObject var store: LifeStore

    @State private var flowUnit: TimeFlowUnit = .second
    @State private var remainingMomentItems: [RemainingMomentItem] = []
    @State private var deletingItem: RemainingMomentItem?
    @State private var showingAddMoment = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    timeFlowHero
                        .padding(.horizontal)

                    rhythmSection
                        .padding(.horizontal)

                    remainingMomentsSection
                        .padding(.horizontal)

                    Spacer(minLength: 20)
                }
                .padding(.vertical, 16)
            }
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("倒數")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: RemainingMomentItem.self) { item in
                RemainingMomentDetailView(
                    item: item,
                    journeyStats: journeyStatsBinding,
                    journeyRecords: journeyRecordsBinding
                )
                .environmentObject(store)
            }
            .onAppear { loadAllData() }
            .sheet(isPresented: $showingAddMoment) {
                AddRemainingMomentView { newItem in
                    remainingMomentItems.append(newItem)
                    saveRemainingMomentItems()
                }
            }
            .alert(
                "刪除項目？",
                isPresented: Binding(
                    get: { deletingItem != nil },
                    set: { if !$0 { deletingItem = nil } }
                ),
                presenting: deletingItem
            ) { item in
                Button("刪除", role: .destructive) {
                    archiveRemainingMoment(item)
                    deletingItem = nil
                }
                Button("取消", role: .cancel) { deletingItem = nil }
            } message: { item in
                Text("「\(item.title)」將被移至封存。")
            }
        }
    }

    // MARK: - Time Flow Hero

    var timeFlowHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("時間正在流動")
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)

            Picker("單位", selection: $flowUnit) {
                ForEach(TimeFlowUnit.allCases) { unit in
                    Text(unit.title).tag(unit)
                }
            }
            .pickerStyle(.segmented)

            TimelineView(.periodic(from: Date(), by: flowUnit.tickInterval)) { context in
                let metrics = LifeMetrics(
                    birthday: store.birthday,
                    lifeExpectancy: store.lifeExpectancy,
                    now: context.date
                )

                Group {
                    if flowUnit == .second {
                        FlipSecondsDisplay(value: Int(metrics.secondsRemaining))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text(flowUnit.displayText(metrics: metrics))
                            .font(.system(size: 34, weight: .light, design: .rounded))
                            .foregroundStyle(LifeTheme.textPrimary)
                            .monospacedDigit()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            Text("剩餘人生的連續刻度，持續變動中。")
                .font(.caption)
                .foregroundStyle(LifeTheme.textTertiary)
        }
        .cardStyle()
    }

    // MARK: - Rhythm

    var rhythmSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("時間節奏")
                .font(.headline)
                .foregroundStyle(LifeTheme.textPrimary)

            TimelineView(.periodic(from: Date(), by: 30)) { context in
                let metrics = LifeMetrics(
                    birthday: store.birthday,
                    lifeExpectancy: store.lifeExpectancy,
                    now: context.date
                )

                VStack(spacing: 14) {
                    RhythmProgressRow(
                        title: "本年已過",
                        progress: metrics.progressOfCurrentYear,
                        tint: LifeTheme.warm
                    )
                    RhythmProgressRow(
                        title: "本週已過",
                        progress: metrics.progressOfCurrentWeek,
                        tint: LifeTheme.accent
                    )
                    RhythmProgressRow(
                        title: "今天已過",
                        progress: metrics.progressOfCurrentDay,
                        tint: LifeTheme.accentEnd
                    )

                    HStack(spacing: 8) {
                        Image(systemName: "sun.horizon.fill")
                            .font(.caption)
                            .foregroundStyle(LifeTheme.accent)
                        Text(String(format: "今天還剩 %.1f 小時", metrics.hoursRemainingToday))
                            .font(.subheadline)
                            .foregroundStyle(LifeTheme.textSecondary)
                            .monospacedDigit()
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Remaining Moments

    var remainingMomentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("你還有幾次？")
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)
                Spacer()
                Button(action: { showingAddMoment = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(LifeTheme.accent)
                }
            }

            if activeRemainingMomentItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 28))
                        .foregroundStyle(LifeTheme.textTertiary)
                    Text("在總覽完成問卷，或手動新增項目")
                        .font(.subheadline)
                        .foregroundStyle(LifeTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .cardStyle(padding: 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(activeRemainingMomentItems) { item in
                        NavigationLink(value: item) {
                            momentCard(for: item)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) { deletingItem = item } label: {
                                Label("刪除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }

    var activeRemainingMomentItems: [RemainingMomentItem] {
        remainingMomentItems.filter { !$0.isArchived }
    }

    func momentCard(for item: RemainingMomentItem) -> some View {
        let remaining = item.estimatedRemainingOccurrences(store: store, metrics: store.metrics)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: item.iconName)
                    .foregroundStyle(LifeTheme.accent)
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)
                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("約剩")
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textSecondary)
                Text("\(remaining.formatted())")
                    .font(.system(size: 32, weight: .light, design: .rounded))
                    .foregroundStyle(LifeTheme.warm)
                Text(item.unit)
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textSecondary)
            }

            Text(item.frequency.displayName)
                .font(.caption)
                .foregroundStyle(LifeTheme.textTertiary)
        }
        .cardStyle(padding: 16)
    }

    // MARK: - Journey bindings for detail sync

    private var journeyStatsBinding: Binding<[LifeJourneyStatItem]> {
        Binding(
            get: {
                LocalJSONStore.load(
                    [LifeJourneyStatItem].self,
                    key: StorageKey.lifeJourneyStatItems,
                    defaultValue: []
                )
            },
            set: { LocalJSONStore.save($0, key: StorageKey.lifeJourneyStatItems) }
        )
    }

    private var journeyRecordsBinding: Binding<[LifeJourneyStatRecord]> {
        Binding(
            get: {
                LocalJSONStore.load(
                    [LifeJourneyStatRecord].self,
                    key: StorageKey.lifeJourneyStatRecords,
                    defaultValue: []
                )
            },
            set: { LocalJSONStore.save($0, key: StorageKey.lifeJourneyStatRecords) }
        )
    }

    func archiveRemainingMoment(_ item: RemainingMomentItem) {
        guard let index = remainingMomentItems.firstIndex(where: { $0.id == item.id }) else { return }
        remainingMomentItems[index].isArchived = true
        saveRemainingMomentItems()
    }

    func saveRemainingMomentItems() {
        LocalJSONStore.save(remainingMomentItems, key: StorageKey.remainingMomentItems)
    }

    func loadAllData() {
        remainingMomentItems = LocalJSONStore.load(
            [RemainingMomentItem].self,
            key: StorageKey.remainingMomentItems,
            defaultValue: []
        )
        if RemainingMomentItem.migrateLegacyParentDependency(&remainingMomentItems) {
            saveRemainingMomentItems()
        }
    }
}

#Preview {
    CountdownView()
        .environmentObject(LifeStore())
}
