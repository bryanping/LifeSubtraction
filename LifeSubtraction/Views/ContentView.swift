import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: LifeStore
    @StateObject private var storeManager = StoreManager.shared
    @State private var selectedTab = AppConstants.MainTab.overview.rawValue

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
    }

    var body: some View {
        ZStack {
            LifeTheme.subtleBackground.ignoresSafeArea()

            if !store.hasCompletedOnboarding {
                OnboardingView()
                    .environmentObject(storeManager)
            } else {
                TabView(selection: $selectedTab) {
                    OverviewView(selectedTab: $selectedTab)
                        .tabItem { Label("總覽", systemImage: "chart.pie.fill") }
                        .tag(AppConstants.MainTab.overview.rawValue)
                    CountdownView()
                        .tabItem { Label("時間", systemImage: "hourglass") }
                        .tag(AppConstants.MainTab.countdown.rawValue)
                    LifeGoalsView()
                        .tabItem { Label("規劃", systemImage: "star.fill") }
                        .tag(AppConstants.MainTab.goals.rawValue)
                    SettingsView()
                        .tabItem { Label("設定", systemImage: "gearshape.fill") }
                        .tag(AppConstants.MainTab.settings.rawValue)
                }
                .tint(LifeTheme.accent)
                .environmentObject(storeManager)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environmentObject(LifeStore())
}
