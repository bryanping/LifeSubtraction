import SwiftUI

// MARK: - PremiumGate ViewModifier  // modified
// 暗色玻璃風 lock overlay。

struct PremiumGate: ViewModifier {
    @EnvironmentObject var storeManager: StoreManager
    @State private var showPaywall = false

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if !storeManager.isPremium {
                        lockedOverlay
                    }
                }
            )
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(storeManager)
            }
    }

    var lockedOverlay: some View {
        ZStack {
            // 半透明深底  // modified
            Rectangle()
                .fill(Color.black.opacity(0.55))
                .background(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LifeTheme.accentSoft)
                        .frame(width: 72, height: 72)
                        .shadow(color: LifeTheme.accent.opacity(0.35), radius: 20) // // modified
                    Image(systemName: "lock.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(LifeTheme.accent)
                }

                Text("完整版功能")
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)                // // modified
                Text("解鎖後即可使用")
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textSecondary)              // // modified

                PrimaryButton("解鎖") {                                     // // modified
                    showPaywall = true
                }
                .padding(.horizontal, 60)
                .padding(.top, 6)
            }
        }
        .ignoresSafeArea()
    }
}

extension View {
    func premiumGate() -> some View {
        modifier(PremiumGate())
    }
}

// MARK: - PremiumBadge  // modified

struct PremiumBadge: View {
    @EnvironmentObject var storeManager: StoreManager

    var body: some View {
        if !storeManager.isPremium {
            Image(systemName: "lock.fill")
                .font(.system(size: 9))
                .foregroundStyle(Color.white)                              // // modified
                .padding(3)
                .background(LifeTheme.warm)                                // // modified
                .clipShape(Circle())
                .offset(x: 10, y: -10)
        }
    }
}
