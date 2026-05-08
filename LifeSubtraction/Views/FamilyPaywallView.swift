import SwiftUI

// 修改内容 — 家人系統付費牆
struct FamilyPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var storeManager: StoreManager

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    iconHeader

                    VStack(spacing: 10) {
                        Text("解鎖更多重要的人")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(LifeTheme.textPrimary)

                        Text("新增更多家人，記錄你們的見面、通話、旅行與陪伴。")
                            .font(.subheadline)
                            .foregroundStyle(LifeTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    featureList

                    PrimaryButton("升級解鎖 \(storeManager.formattedPrice)", icon: "sparkles") {
                        Task { await storeManager.purchase() }
                    }

                    Button("稍後再說") { dismiss() }
                        .font(.subheadline)
                        .foregroundStyle(LifeTheme.textSecondary)

                    Button("還原購買") {
                        Task { await storeManager.restore() }
                    }
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textTertiary)
                }
                .padding()
            }
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(LifeTheme.textTertiary)
                    }
                }
            }
        }
    }

    var iconHeader: some View {
        ZStack {
            Circle()
                .fill(LifeTheme.accentSoft)
                .frame(width: 86, height: 86)
            Image(systemName: "person.2.fill")
                .font(.system(size: 36))
                .foregroundStyle(LifeTheme.accent)
        }
        .padding(.top, 20)
    }

    var featureList: some View {
        VStack(spacing: 12) {
            paywallFeature(icon: "person.2.fill",
                           title: "無限制新增家人",
                           subtitle: "父母、伴侶、孩子、寵物都能記錄")
            paywallFeature(icon: "heart.text.square.fill",
                           title: "共同剩餘時間",
                           subtitle: "計算你們還剩多少見面與陪伴機會")
            paywallFeature(icon: "clock.arrow.circlepath",
                           title: "相處記錄",
                           subtitle: "記錄每次見面、通話、旅行與重要回憶")
            paywallFeature(icon: "sparkles",
                           title: "人生優先級提醒",
                           subtitle: "幫你把時間留給真正重要的人")
        }
        .cardStyle()
    }

    func paywallFeature(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(LifeTheme.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textSecondary)
            }
            Spacer()
        }
    }
}
