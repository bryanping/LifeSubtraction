import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: LifeStore
    @StateObject private var storeManager = StoreManager.shared

    init() {
        // 全 App 使用半透明深色 TabBar  // modified
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        // NavigationBar 大標題：透明 + 白色文字  // modified
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
    }

    var body: some View {
        ZStack {
            LifeTheme.subtleBackground.ignoresSafeArea()  // // modified — 全 App 深藍黑底

            if !store.hasCompletedOnboarding {
                OnboardingView()
                    .environmentObject(storeManager)
            } else {
                TabView {
                    OverviewView()
                        .tabItem { Label("總覽", systemImage: "chart.pie.fill") }
                    WeekGridView()
                        .tabItem { Label("生命週", systemImage: "squareshape.split.3x3") }
                    CountdownView()
                        .premiumGate()
                        .tabItem { Label("倒數", systemImage: "hourglass") }
                    ValuesView()
                        .premiumGate()
                        .tabItem { Label("價值觀", systemImage: "heart.fill") }
                    SettingsView()
                        .tabItem { Label("設定", systemImage: "gearshape.fill") }
                }
                .tint(LifeTheme.accent)
                .environmentObject(storeManager)
            }
        }
        .preferredColorScheme(.dark) // // modified — 鎖定暗色，讓系統元件配合
    }
}
