import SwiftUI

@main
struct LifeSubtractionApp: App {
    @StateObject private var store = LifeStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear {
                    NotificationManager.shared.requestPermission()
                }
        }
    }
}
