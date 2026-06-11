import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var store: LifeStore
    @EnvironmentObject var storeManager: StoreManager

    @State private var heroUnit: OverviewHeroUnit = .years
    @State private var journeyStatItems: [LifeJourneyStatItem] = []
    @State private var journeyStatRecords: [LifeJourneyStatRecord] = []
    @State private var reflectionDraft = ""
    @State private var reflectionEntries: [ReflectionEntry] = []
    @State private var showingAddJourneyStat = false
    @State private var showingQuestionnaire = false
    @State private var editingJourneyStat: LifeJourneyStatItem?
    @State private var deletingJourneyStat: LifeJourneyStatItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                        .padding(.horizontal)

                    todayReminderCard
                        .padding(.horizontal)

                    dailyReflectionCard
                        .padding(.horizontal)

                    lifeJourneyStatsSection
                        .padding(.horizontal)

                    yearReviewSection
                        .padding(.horizontal)
                }
                .padding(.vertical, 16)
            }
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("總覽")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadAllData()
                if !JourneyStatsBootstrap.isQuestionnaireDone && activeJourneyStatItems.isEmpty {
                    showingQuestionnaire = true
                }
            }
            .sheet(isPresented: $showingQuestionnaire) {
                JourneyStatsQuestionnaireView { stats, moments in
                    journeyStatItems = stats
                    saveJourneyStatItems()
                    LocalJSONStore.save(moments, key: StorageKey.remainingMomentItems)
                }
                .environmentObject(store)
            }
            .sheet(isPresented: $showingAddJourneyStat) {
                AddLifeJourneyStatView(existingItems: journeyStatItems) { newItem in
                    journeyStatItems.append(newItem)
                    saveJourneyStatItems()
                }
            }
            .sheet(item: $editingJourneyStat) { item in
                AddLifeJourneyStatView(existing: item, existingItems: journeyStatItems) { updated in
                    if let index = journeyStatItems.firstIndex(where: { $0.id == updated.id }) {
                        journeyStatItems[index] = updated
                        saveJourneyStatItems()
                    }
                }
            }
            .alert(
                "刪除項目？",
                isPresented: Binding(
                    get: { deletingJourneyStat != nil },
                    set: { if !$0 { deletingJourneyStat = nil } }
                ),
                presenting: deletingJourneyStat
            ) { item in
                Button("刪除", role: .destructive) {
                    archiveJourneyStat(item)
                    deletingJourneyStat = nil
                }
                Button("取消", role: .cancel) {
                    deletingJourneyStat = nil
                }
            } message: { item in
                Text("「\(item.title)」將被移除。")
            }
        }
    }

    // MARK: - Hero

    var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 20) {
                LifeRemainingRing(percent: store.metrics.percentRemaining)
                    .frame(width: 116, height: 116)

                VStack(alignment: .leading, spacing: 10) {
                    Text("人生還剩")
                        .font(.subheadline)
                        .foregroundStyle(LifeTheme.textSecondary)

                    Button {
                        withAnimation(.snappy) { cycleHeroUnit() }
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(heroUnit.valueText(metrics: store.metrics))
                                .font(.system(size: 36, weight: .semibold, design: .rounded))
                                .foregroundStyle(LifeTheme.accent)
                                .monospacedDigit()
                            Text(heroUnit.label)
                                .font(.headline)
                                .foregroundStyle(LifeTheme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)

                    Text("點擊數字切換單位")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textTertiary)
                }
            }

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5)

            NavigationLink {
                SettingsView()
                    .environmentObject(storeManager)
            } label: {
                HStack(spacing: 4) {
                    Text("預計壽命 \(store.lifeExpectancy) 歲")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textTertiary)
                    Image(systemName: "pencil")
                        .font(.caption2)
                        .foregroundStyle(LifeTheme.textQuaternary)
                }
            }
            .buttonStyle(.plain)
        }
        .cardStyle()
    }

    func cycleHeroUnit() {
        let all = OverviewHeroUnit.allCases
        guard let index = all.firstIndex(of: heroUnit) else { return }
        heroUnit = all[(index + 1) % all.count]
    }

    // MARK: - Today Reminder

    var todayReminderCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .foregroundStyle(LifeTheme.warm)
            Text("今晚，留一點時間給真正重要的事。")
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 16)
    }

    // MARK: - Daily Reflection

    var dailyReflectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Reflection")
                .font(.headline)
                .foregroundStyle(LifeTheme.textPrimary)

            Text("今天最值得留下的是？")
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)

            TextField("寫下一句話…", text: $reflectionDraft, axis: .vertical)
                .lineLimit(2...4)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )
                .foregroundStyle(LifeTheme.textPrimary)

            Button(action: saveDailyReflection) {
                Text("保存")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(
                        reflectionDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? LifeTheme.textTertiary
                            : LifeTheme.accent
                    )
            }
            .disabled(reflectionDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .cardStyle()
    }

    // MARK: - Life Journey Stats

    var lifeJourneyStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("人生累積")
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)

                Spacer()

                Button(action: { showingAddJourneyStat = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(LifeTheme.accent)
                }
            }

            if activeJourneyStatItems.isEmpty {
                VStack(spacing: 10) {
                    Text("先完成問卷，建立你的累積項目")
                        .font(.subheadline)
                        .foregroundStyle(LifeTheme.textSecondary)
                    SecondaryButton("開始問卷", icon: "list.bullet.clipboard") {
                        showingQuestionnaire = true
                    }
                }
                .frame(maxWidth: .infinity)
                .cardStyle(padding: 20)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(activeJourneyStatItems) { item in
                        journeyStatCard(for: item)
                            .onTapGesture { editingJourneyStat = item }
                            .contextMenu {
                                Button { editingJourneyStat = item } label: {
                                    Label("編輯", systemImage: "pencil")
                                }
                                Button(role: .destructive) { deletingJourneyStat = item } label: {
                                    Label("刪除", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }

    var activeJourneyStatItems: [LifeJourneyStatItem] {
        journeyStatItems.filter { !$0.isArchived }
    }

    func journeyStatCard(for item: LifeJourneyStatItem) -> some View {
        let total = JourneyStatCalculator.totalCount(item: item, records: journeyStatRecords)
        let thisMonth = JourneyStatCalculator.thisMonthCount(itemId: item.id, records: journeyStatRecords)
        let lastMonth = JourneyStatCalculator.lastMonthCount(itemId: item.id, records: journeyStatRecords)

        return VStack(alignment: .leading, spacing: 8) {
            Image(systemName: item.iconName)
                .font(.caption)
                .foregroundStyle(LifeTheme.accent)

            Text("\(total.formatted()) \(item.unit)")
                .font(.headline)
                .foregroundStyle(LifeTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(item.title)
                .font(.caption)
                .foregroundStyle(LifeTheme.textTertiary)

            Text("上月 +\(lastMonth) · 本月 +\(thisMonth)")
                .font(.caption2)
                .foregroundStyle(LifeTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    // MARK: - Year Review

    var yearReviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("年度回顧")
                .font(.headline)
                .foregroundStyle(LifeTheme.textPrimary)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("\(currentYear) 已經走過")
                        .font(.subheadline)
                        .foregroundStyle(LifeTheme.textSecondary)
                    Spacer()
                    Text("\(yearProgressPercent)%")
                        .font(.headline)
                        .foregroundStyle(LifeTheme.accent)
                }

                ProgressBar(value: yearProgress)

                if activeJourneyStatItems.isEmpty {
                    Text("完成問卷後，這裡會依累積項目回顧這一年。")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textTertiary)
                } else {
                    ForEach(activeJourneyStatItems.prefix(4)) { item in
                        let count = JourneyStatCalculator.thisMonthCount(
                            itemId: item.id,
                            records: journeyStatRecords
                        )
                        yearReviewRow(
                            label: item.title,
                            value: "本月 +\(count) \(item.unit)",
                            icon: item.iconName
                        )
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LifeTheme.glassFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
            )
        }
    }

    func yearReviewRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(LifeTheme.accent)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textPrimary)
        }
    }

    var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    var yearProgress: Double {
        store.metrics.progressOfCurrentYear
    }

    var yearProgressPercent: Int {
        Int((yearProgress * 100).rounded())
    }

    // MARK: - Data

    func loadAllData() {
        journeyStatItems = LocalJSONStore.load(
            [LifeJourneyStatItem].self,
            key: StorageKey.lifeJourneyStatItems,
            defaultValue: []
        )
        journeyStatRecords = LocalJSONStore.load(
            [LifeJourneyStatRecord].self,
            key: StorageKey.lifeJourneyStatRecords,
            defaultValue: []
        )
        reflectionEntries = LocalJSONStore.load(
            [ReflectionEntry].self,
            key: ReflectionEntry.storageKey,
            defaultValue: []
        )
        reflectionDraft = ReflectionEntry.current(in: reflectionEntries, period: .daily)?.text ?? ""
    }

    func saveJourneyStatItems() {
        LocalJSONStore.save(journeyStatItems, key: StorageKey.lifeJourneyStatItems)
    }

    func saveDailyReflection() {
        let trimmed = reflectionDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        ReflectionEntry.upsert(text: trimmed, period: .daily, in: &reflectionEntries)
        LocalJSONStore.save(reflectionEntries, key: ReflectionEntry.storageKey)
    }

    func archiveJourneyStat(_ item: LifeJourneyStatItem) {
        guard let index = journeyStatItems.firstIndex(where: { $0.id == item.id }) else { return }
        journeyStatItems[index].isArchived = true
        saveJourneyStatItems()
    }
}

#Preview {
    OverviewView()
        .environmentObject(LifeStore())
        .environmentObject(StoreManager.shared)
}
