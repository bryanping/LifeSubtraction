import SwiftUI

struct WatchRootView: View {
    @State private var metrics: LifeMetrics = LifeMetrics.loadFromShared()
    @State private var selection = 0

    // 每分鐘 tick 一次更新進度
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView(selection: $selection) {
            WatchOverviewView(metrics: metrics)
                .tag(0)
            WatchYearProgressView(metrics: metrics)
                .tag(1)
            WatchWeekProgressView(metrics: metrics)
                .tag(2)
            WatchReflectionView()
                .tag(3)
        }
        .tabViewStyle(.verticalPage)
        .onReceive(timer) { _ in
            metrics = LifeMetrics.loadFromShared()
        }
        .onAppear {
            metrics = LifeMetrics.loadFromShared()
        }
    }
}

#Preview {
    WatchRootView()
}
