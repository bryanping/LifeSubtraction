import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: LifeStore
    @StateObject private var storeManager = StoreManager.shared

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
                TabView {
                    OverviewView()
                        .tabItem { Label("總覽", systemImage: "chart.pie.fill") }
                    CountdownView()
                //        .premiumGate()
                        .tabItem { Label("倒數", systemImage: "hourglass") }
                    ValuesView()
                //        .premiumGate()
                        .tabItem { Label("人生目標", systemImage: "target") }
                    SettingsView()
                        .tabItem { Label("設定", systemImage: "gearshape.fill") }
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
