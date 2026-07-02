import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var store: LifeStore
    @EnvironmentObject var storeManager: StoreManager
    @Binding var selectedTab: Int

    @State private var moments: [LifeMoment] = []
    @State private var activeGoals: [LifeGoal] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                heroCard
                recentMomentsSection
                Spacer(minLength: 0)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("總覽")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { loadAllData() }
        }
    }

    // MARK: - Hero

    var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            TimelineView(.periodic(from: Date(), by: 0.1)) { ctx in
                let metrics = LifeMetrics(
                    birthday: store.birthday,
                    lifeExpectancy: store.lifeExpectancy,
                    now: ctx.date
                )
                LifeStopwatchRingsView(metrics: metrics)
            }

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5)

            HStack(spacing: 10) {
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

                MarqueeText(text: DailyReminder.today())
            }
        }
        .cardStyle()
    }

    // MARK: - 進行中（最多 2 筆，點選跳轉規劃頁）

    var activeGoalsList: [LifeGoal] {
        activeGoals
            .filter { $0.status == .active }
            .sorted { ($0.startDate ?? .distantPast) > ($1.startDate ?? .distantPast) }
    }

    var recentActiveGoals: [LifeGoal] {
        Array(activeGoalsList.prefix(2))
    }

    var recentMomentsSection: some View {
        Group {
            if !recentActiveGoals.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("進行中")
                            .font(.headline)
                            .foregroundStyle(LifeTheme.textPrimary)
                        Spacer()
                        Button {
                            selectedTab = AppConstants.MainTab.goals.rawValue
                        } label: {
                            Text("其他")
                                .font(.caption)
                                .foregroundStyle(LifeTheme.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }

                    ForEach(recentActiveGoals) { goal in
                        Button {
                            selectedTab = AppConstants.MainTab.goals.rawValue
                        } label: {
                            activeGoalRow(goal)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func activeGoalRow(_ goal: LifeGoal) -> some View {
        HStack(spacing: 12) {
            Image(systemName: goal.category.iconName)
                .foregroundStyle(LifeTheme.warm)
                .font(.system(size: 18))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(LifeTheme.textPrimary)
                    .lineLimit(1)
                if let start = goal.startDate {
                    let days = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
                    Text("已進行 \(max(0, days) + 1) 天")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textTertiary)
                }
            }
            Spacer()
            if !goal.stages.isEmpty {
                Text("\(goal.completedStageCount)/\(goal.stages.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(LifeTheme.accent)
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

    // MARK: - Data

    func loadAllData() {
        moments = LocalJSONStore.load([LifeMoment].self, key: StorageKey.lifeMoments, defaultValue: [])
        activeGoals = LocalJSONStore.load([LifeGoal].self, key: StorageKey.lifeGoals, defaultValue: [])
    }
}

#Preview {
    OverviewView(selectedTab: .constant(AppConstants.MainTab.overview.rawValue))
        .environmentObject(LifeStore())
        .environmentObject(StoreManager.shared)
}
