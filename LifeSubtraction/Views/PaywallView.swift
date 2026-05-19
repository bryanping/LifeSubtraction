import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            LifeTheme.subtleBackground.ignoresSafeArea()                  // // modified

            // 微光暈  // modified
            RadialGradient(
                colors: [LifeTheme.accent.opacity(0.20), .clear],
                center: .top, startRadius: 0, endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.white.opacity(0.40))    // // modified
                    }
                    .padding()
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(LifeTheme.accentSoft)
                        .frame(width: 100, height: 100)
                        .shadow(color: LifeTheme.accent.opacity(0.4), radius: 30) // // modified — glow
                    Image(systemName: "infinity")
                        .font(.system(size: 44))
                        .foregroundStyle(LifeTheme.accent)
                }
                .padding(.bottom, 24)

                Text("人生減法 完整版")
                    .font(.title2).fontWeight(.bold)
                    .foregroundStyle(LifeTheme.textPrimary)                // // modified
                    .padding(.bottom, 8)

                Text("一次付費，永久使用")
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textSecondary)              // // modified
                    .padding(.bottom, 32)

                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "checkmark.circle.fill", text: "今日反思日記", sub: "每天記錄讓未來感謝的事")
                    FeatureRow(icon: "checkmark.circle.fill", text: "價值觀清單", sub: "寫下你最重視的事，讓選擇有方向")
                    FeatureRow(icon: "checkmark.circle.fill", text: "每日提醒訊息", sub: "每晚溫和地問你今天過得怎樣")
                    FeatureRow(icon: "checkmark.circle.fill", text: "未來所有更新", sub: "永久免費升級新功能")
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 36)

                if storeManager.isLoading {
                    ProgressView()
                        .tint(LifeTheme.accent)                            // // modified
                        .frame(height: 54)
                } else {
                    PrimaryButton("解鎖完整版 · \(storeManager.formattedPrice)") { // // modified
                        Task { await storeManager.purchase() }
                    }
                    .padding(.horizontal, 32)
                }

                if let error = storeManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.red.opacity(0.85))          // // modified
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                }

                Button("已購買？點此還原") {
                    Task { await storeManager.restore() }
                }
                .font(.footnote)
                .foregroundStyle(LifeTheme.textTertiary)                   // // modified
                .padding(.top, 16)

                Spacer()

                HStack(spacing: 16) {
                    Link("隱私政策", destination: URL(string: "https://yoursite.com/privacy")!)
                        .foregroundStyle(LifeTheme.textTertiary)
                    Text("·").foregroundStyle(LifeTheme.textTertiary)
                    Link("使用條款", destination: URL(string: "https://yoursite.com/terms")!)
                        .foregroundStyle(LifeTheme.textTertiary)
                }
                .font(.caption)
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            Task { await storeManager.loadProducts() }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let sub: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(LifeTheme.accent)
                .font(.body)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(LifeTheme.textPrimary)                // // modified
                Text(sub)
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textSecondary)              // // modified
            }
        }
    }
}
