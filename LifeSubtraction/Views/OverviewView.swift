import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var store: LifeStore

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    heroCard
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(label: "已活過天數", value: store.daysLived.formatted(), sub: "在你身後", icon: "arrow.left")
                        StatCard(label: "剩餘天數", value: store.daysRemaining.formatted(), sub: "在你前方", icon: "arrow.right", accent: true)
                        StatCard(label: "已用生命", value: "\(Int(store.percentUsed * 100))%", sub: "已完成", icon: "chart.pie.fill")
                        StatCard(label: "現在年齡", value: "\(store.ageYears)", sub: "歲", icon: "person.fill")
                    }
                    .padding(.horizontal)

                    progressBar
                        .padding(.horizontal)

                    countdownSection
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                }
                .padding(.vertical, 8)
            }
            .scrollContentBackground(.hidden)                  // // modified — 不蓋住底色
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("人生減法")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)   // // modified
        }
    }

    // MARK: - Hero  // modified — 大號數字 + 內嵌進度條，去掉花俏紋理

    var heroCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LifeTheme.heroGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 0.5) // // modified
                )

            VStack(spacing: 6) {
                Text("剩餘的時間")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.85))            // // modified
                Text(store.daysRemaining.formatted())
                    .font(.system(size: 76, weight: .light, design: .rounded))
                    .foregroundStyle(Color.white)                          // // modified
                    .padding(.top, -2)
                Text("天")
                    .font(.title3)
                    .foregroundStyle(Color.white.opacity(0.85))            // // modified
                    .padding(.top, -10)

                // 內嵌進度條  // modified
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("生命進度")
                            .font(.caption).foregroundStyle(Color.white.opacity(0.85))
                        Spacer()
                        Text("\(Int(store.percentUsed * 100))% / 100%")
                            .font(.caption).foregroundStyle(Color.white.opacity(0.85))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.25))      // // modified
                            Capsule().fill(Color.white)                    // // modified
                                .frame(width: geo.size.width * store.percentUsed)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.top, 14)
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 28)
        }
        .frame(maxWidth: .infinity)
        .shadow(color: LifeTheme.accent.opacity(0.20), radius: 20, y: 10) // // modified — 微 glow
    }

    // MARK: - 總體進度  // modified

    var progressBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "hourglass.bottomhalf.filled")
                    .foregroundStyle(LifeTheme.accent)
                Text("總體進度")
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(LifeTheme.textPrimary)                // // modified
                Spacer()
                Text("\(Int(store.percentUsed * 100))%")
                    .font(.system(.caption, design: .rounded)).fontWeight(.semibold)
                    .foregroundStyle(LifeTheme.accent)
            }
            ProgressBar(value: store.percentUsed)
            Text("已使用 \(Int(store.percentUsed * 100))%，剩餘 \(100 - Int(store.percentUsed * 100))%")
                .font(.caption)
                .foregroundStyle(LifeTheme.textSecondary)                  // // modified
        }
        .cardStyle()
    }

    // MARK: - 你還有幾次  // modified

    var countdownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("你還有幾次？")
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)                // // modified
                Spacer()
                Image(systemName: "infinity.circle.fill")
                    .foregroundStyle(LifeTheme.accentEnd)                  // // modified
            }

            VStack(spacing: 0) {
                CountdownRow(icon: "sparkles", color: LifeTheme.warm, label: "新年", count: store.newYearsLeft, unit: "次")
                divider
                CountdownRow(icon: "airplane", color: LifeTheme.accent, label: "出國旅行（每年一次）", count: store.tripsLeft, unit: "次")
                divider
                CountdownRow(icon: "heart", color: LifeTheme.accentEnd, label: "探望父母（每月一次）", count: store.parentVisitsLeft, unit: "次")
                divider
                CountdownRow(icon: "book", color: LifeTheme.accent, label: "讀一本書（每月一本）", count: store.booksLeft, unit: "本")
                divider
                CountdownRow(icon: "sun.max", color: LifeTheme.warm, label: "夏天", count: store.summersLeft, unit: "個")
            }
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LifeTheme.glassFill)                              // // modified
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
            )
        }
    }

    // 統一 divider 樣式  // modified
    var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 0.5)
            .padding(.leading, 56)
    }
}

// MARK: - StatCard  // modified

struct StatCard: View {
    let label: String
    let value: String
    let sub: String
    var icon: String = "circle"
    var accent: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textSecondary)              // // modified
                Spacer()
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(accent ? LifeTheme.accent : LifeTheme.textTertiary) // // modified
            }
            Text(value)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(accent ? LifeTheme.accent : LifeTheme.textPrimary) // // modified
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(sub)
                .font(.caption2)
                .foregroundStyle(LifeTheme.textTertiary)                   // // modified
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LifeTheme.glassFill)                                  // // modified
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accent ? LifeTheme.accentMuted : LifeTheme.glassBorder, lineWidth: 0.5) // // modified
        )
    }
}

// MARK: - CountdownRow  // modified

struct CountdownRow: View {
    let icon: String
    var color: Color = LifeTheme.accent
    let label: String
    let count: Int
    let unit: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))                              // // modified
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
            }
            Text(label)
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textPrimary)                    // // modified
            Spacer()
            Text("\(count.formatted())")
                .font(.system(.subheadline, design: .rounded)).fontWeight(.semibold)
                .foregroundStyle(LifeTheme.textPrimary)                    // // modified
            Text(unit)
                .font(.caption)
                .foregroundStyle(LifeTheme.textSecondary)                  // // modified
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
