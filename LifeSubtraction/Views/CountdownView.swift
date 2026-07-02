import SwiftUI

struct CountdownView: View {
    @EnvironmentObject var store: LifeStore

    @State private var heroUnit: TimeFlowHeroUnit = .yearDays

    @State private var activeGoals: [LifeGoal] = []
    @State private var tasks: [LifeTask] = []
    @State private var familyMembers: [FamilyMember] = []
    @State private var moments: [LifeMoment] = []
    @State private var navigationPath = NavigationPath()
    // 修改内容 — 推薦批次，讓刷新按鈕可以切換不同推薦
    @State private var recommendBatch: Int = 0

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 0) {

                    // ── 修改内容：頂部區塊（LCD + 時間感），控制在 1/3 畫面以内 ──
                    LCDTimeFlowSection(
                        birthday: store.birthday,
                        lifeExpectancy: store.lifeExpectancy,
                        heroUnit: $heroUnit
                    )

                    // 分隔線
                    Rectangle()
                        .fill(Color.white.opacity(0.07))
                        .frame(height: 0.5)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)

                    // ── 修改内容：時間情境推薦，僅顯示今天可做的小行動 ──
                    TimeRecommendationSection(
                        heroUnit: heroUnit,
                        birthday: store.birthday,
                        lifeExpectancy: store.lifeExpectancy,
                        goals: activeGoals,
                        tasks: tasks,
                        familyMembers: familyMembers,
                        batch: recommendBatch,
                        onAction: handleRecommendationAction,
                        onRefresh: { recommendBatch += 1 }
                    )
                    .padding(.horizontal, 20)

                    Spacer(minLength: 32)
                }
                .padding(.vertical, 8)
            }
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("時間")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadGoals)
            // 切換 unit 時重置批次
            .onChange(of: heroUnit) { _, _ in recommendBatch = 0 }
            .navigationDestination(for: GoalRoute.self) { route in
                LifeGoalDetailView(
                    goals: $activeGoals,
                    moments: $moments,
                    goalId: route.goalId,
                    startInEditMode: route.startInEditMode
                )
            }
        }
    }

    private func loadGoals() {
        activeGoals = LocalJSONStore.load([LifeGoal].self, key: StorageKey.lifeGoals, defaultValue: [])
        tasks = LocalJSONStore.load([LifeTask].self, key: StorageKey.lifeTasks, defaultValue: [])
        familyMembers = LocalJSONStore.load([FamilyMember].self, key: StorageKey.familyMembers, defaultValue: [])
        moments = LocalJSONStore.load([LifeMoment].self, key: StorageKey.lifeMoments, defaultValue: [])
    }

    private func handleRecommendationAction(_ action: TimeRecommendationAction) {
        switch action {
        case let .addTask(title, category, minutes):
            let duplicate = tasks.contains {
                $0.isPending && $0.title.trimmingCharacters(in: .whitespacesAndNewlines) == title
            }
            guard !duplicate else { return }
            let task = LifeTask(title: title, category: category, estimatedMinutes: minutes, isStarred: true)
            tasks.insert(task, at: 0)
            LocalJSONStore.save(tasks, key: StorageKey.lifeTasks)

        case let .openGoal(goalId):
            navigationPath.append(GoalRoute(goalId: goalId, startInEditMode: true))

        case .none:
            break
        }
    }
}

#Preview {
    CountdownView()
        .environmentObject(LifeStore())
}
