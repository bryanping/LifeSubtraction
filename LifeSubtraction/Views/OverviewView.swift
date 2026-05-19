import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var store: LifeStore

    @State private var reflectionCount = 0
    @State private var completedGoalCount = 0
    @State private var totalGoalCount = 0
    @State private var recordedMomentCount = 0
    @State private var journeyStatItems: [LifeJourneyStatItem] = []
    @State private var showingAddJourneyStat = false
    @State private var editingJourneyStat: LifeJourneyStatItem?
    @State private var deletingJourneyStat: LifeJourneyStatItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                        .padding(.horizontal)

                    lifeJourneyStatsSection
                        .padding(.horizontal)

                    lifeMilestonesSection
                        .padding(.horizontal)

                    lifeMomentsSection
                        .padding(.horizontal)

                    yearReviewSection
                        .padding(.horizontal)
                }
                .padding(.vertical, 16)
            }
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("生活概覽")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
            .onAppear {
                loadAllData()
            }
            .sheet(isPresented: $showingAddJourneyStat) {
                AddLifeJourneyStatView { newItem in
                    journeyStatItems.append(newItem)
                    saveJourneyStatItems()
                }
            }
            .sheet(item: $editingJourneyStat) { item in
                AddLifeJourneyStatView(existing: item) { updated in
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

    // MARK: - Hero Card

    var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 20) {
                LifeJourneyRing(percent: store.percentUsed)
                    .frame(width: 116, height: 116)

                VStack(alignment: .leading, spacing: 14) {
                    (
                        Text("你已經活了 ")
                        + Text(formattedCount(store.daysLived))
                            .foregroundStyle(LifeTheme.accent)
                            .fontWeight(.semibold)
                        + Text(" 天")
                    )
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 10) {

                        journeyDetailRow(
                            icon: "calendar",
                            text: "走過了 \(formattedCount(store.weeksLived)) 個週末"
                        )
                        journeyDetailRow(
                            icon: "gift.fill",
                            text: "慶祝了 \(formattedCount(store.ageYears)) 次生日"
                        )
                    }
                }
            }

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5)

            HStack(alignment: .center) {
                Label {
                    Text("你出生於 \(birthDateText)")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textTertiary)
                } icon: {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textTertiary)
                }

                Spacer()

                NavigationLink(destination: SettingsView()) {
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
        }
        .cardStyle()
    }

    func journeyDetailRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(LifeTheme.accent)
                .frame(width: 16, alignment: .center)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var birthDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "yyyy 年 M 月 d 日"
        return formatter.string(from: store.birthday)
    }

    func formattedCount(_ value: Int) -> String {
        value.formatted(.number.grouping(.automatic))
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
                .contentShape(Rectangle())
            }

            if activeJourneyStatItems.isEmpty {
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(LifeTheme.textTertiary)
                    Text("添加你的第一個累積項目")
                        .font(.subheadline)
                        .foregroundStyle(LifeTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LifeTheme.glassFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
                )
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(activeJourneyStatItems) { item in
                        journeyStatCard(for: item)
                            .onTapGesture {
                                editingJourneyStat = item
                            }
                            .contextMenu {
                                Button {
                                    editingJourneyStat = item
                                } label: {
                                    Label("編輯", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    deletingJourneyStat = item
                                } label: {
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
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: item.iconName)
                .font(.caption)
                .foregroundStyle(LifeTheme.accent)
            Text(item.displayValue(store: store, daysPassedThisYear: daysPassedThisYear))
                .font(.headline)
                .foregroundStyle(LifeTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(item.title)
                .font(.caption)
                .foregroundStyle(LifeTheme.textTertiary)
                .lineLimit(2)
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

    func archiveJourneyStat(_ item: LifeJourneyStatItem) {
        guard let index = journeyStatItems.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        journeyStatItems[index].isArchived = true
        saveJourneyStatItems()
    }

    func saveJourneyStatItems() {
        LocalJSONStore.save(journeyStatItems, key: "life-journey-stat-items")
    }

    var daysPassedThisYear: Int {
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        guard let startOfYear = cal.date(from: DateComponents(year: year, month: 1, day: 1)) else {
            return 0
        }
        return max(1, (cal.dateComponents([.day], from: startOfYear, to: Date()).day ?? 0) + 1)
    }

    // MARK: - Life Milestones

    var lifeMilestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("人生里程碑")
                .font(.headline)
                .foregroundStyle(LifeTheme.textPrimary)

            Text("那些改變人生軌跡的時刻")
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)

            VStack(spacing: 0) {
                milestonePlaceholderRow(title: "第 10,000 天", subtitle: "即將到來", icon: "flag.fill")
                milestoneDivider
                milestonePlaceholderRow(title: "第一次旅行", subtitle: "待記錄", icon: "airplane")
                milestoneDivider
                milestonePlaceholderRow(title: "畢業", subtitle: "待記錄", icon: "graduationcap.fill")
                milestoneDivider
                milestonePlaceholderRow(title: "重要轉折", subtitle: "待記錄", icon: "arrow.triangle.turn.up.right.diamond.fill")
            }
            .padding(4)
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

    var milestoneDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 0.5)
            .padding(.leading, 52)
    }

    func milestonePlaceholderRow(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(LifeTheme.accent)
                .frame(width: 36, height: 36)
                .background(LifeTheme.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textTertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(LifeTheme.textQuaternary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Life Moments

    var lifeMomentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("人生時刻")
                .font(.headline)
                .foregroundStyle(LifeTheme.textPrimary)

            Text("記錄那些真正留下來的日子")
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)

            VStack(alignment: .center, spacing: 12) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(LifeTheme.accent.opacity(0.7))

                Text("每一次值得記住的相聚、旅行與轉折，都值得被留下。")
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textSecondary)
                    .multilineTextAlignment(.center)

                if recordedMomentCount > 0 {
                    Text("已記錄 \(recordedMomentCount) 個人生時刻")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.accent)
                } else {
                    Text("即將推出 · 敬請期待")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
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

    // MARK: - Year Review

    var yearReviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("年度回顧")
                .font(.headline)
                .foregroundStyle(LifeTheme.textPrimary)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(currentYear) 已經走過")
                            .font(.subheadline)
                            .foregroundStyle(LifeTheme.textSecondary)
                        Spacer()
                        Text("\(yearProgressPercent)%")
                            .font(.headline)
                            .foregroundStyle(LifeTheme.accent)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(LifeTheme.heroGradient)
                                .frame(width: geo.size.width * yearProgress, height: 6)
                        }
                    }
                    .frame(height: 6)
                }

                yearReviewRow(label: "已記錄反思", value: "\(reflectionCount) 次", icon: "text.book.closed.fill")
                yearReviewRow(label: "已完成目標", value: "\(completedGoalCount) / \(totalGoalCount)", icon: "checkmark.circle.fill")
                yearReviewRow(label: "人生時刻", value: "\(recordedMomentCount) 個", icon: "sparkles")
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
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        guard
            let start = cal.date(from: DateComponents(year: year, month: 1, day: 1)),
            let end = cal.date(from: DateComponents(year: year + 1, month: 1, day: 1))
        else { return 0 }
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return min(1.0, max(0.0, Date().timeIntervalSince(start) / total))
    }

    var yearProgressPercent: Int {
        Int((yearProgress * 100).rounded())
    }

    func loadAllData() {
        loadJourneyStatItems()
        loadYearReviewData()
    }

    func loadJourneyStatItems() {
        journeyStatItems = LocalJSONStore.load(
            [LifeJourneyStatItem].self,
            key: "life-journey-stat-items",
            defaultValue: LifeJourneyStatItem.defaults
        )
    }

    func loadYearReviewData() {
        let reflections = LocalJSONStore.load(
            [ReflectionEntry].self,
            key: ReflectionEntry.storageKey,
            defaultValue: []
        )
        reflectionCount = reflections.count

        let goals = LocalJSONStore.load(
            [LifeGoal].self,
            key: "life-goals",
            defaultValue: []
        )
        totalGoalCount = goals.count
        completedGoalCount = goals.filter(\.isCompleted).count

        let records = LocalJSONStore.load(
            [RemainingMomentRecord].self,
            key: "remaining-moment-records",
            defaultValue: []
        )
        recordedMomentCount = records.count
    }
}

// MARK: - Remaining Moment Row

struct RemainingMomentRow: View {
    let item: RemainingMomentItem
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.iconName)
                .font(.system(size: 18))
                .foregroundStyle(Color.accentColor)
                .frame(width: 32, height: 32)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .foregroundStyle(Color.primary)

                Text(item.frequency.displayName)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(count)")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)

                Text(item.unit)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}

// MARK: - Life Journey Ring

struct LifeJourneyRing: View {
    let percent: Double

    private var percentInt: Int {
        Int((percent * 100).rounded())
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 10)

            Circle()
                .trim(from: 0, to: min(1, max(0, percent)))
                .stroke(
                    LifeTheme.heroGradient,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: percent)

            VStack(spacing: 4) {
                Text("人生旅程")
                    .font(.caption2)
                    .foregroundStyle(LifeTheme.textSecondary)
                Text("已走過 \(percentInt)%")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(LifeTheme.textPrimary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.1))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)

                Text(value)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    let store = LifeStore()
    return NavigationStack {
        OverviewView()
            .environmentObject(store)
    }
}
