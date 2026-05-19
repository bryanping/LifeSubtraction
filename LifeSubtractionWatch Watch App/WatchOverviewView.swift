import SwiftUI

struct WatchOverviewView: View {
    let metrics: LifeMetrics

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("剩餘的時間")
                    .font(.caption2).foregroundStyle(LifeTheme.textSecondary)  // // modified

                Text(metrics.daysRemaining.formatted())
                    .font(.system(size: 44, weight: .light, design: .rounded))
                    .foregroundStyle(LifeTheme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("天")
                    .font(.caption).foregroundStyle(LifeTheme.textSecondary)  // // modified
                    .padding(.top, -8)

                ProgressLine(value: metrics.percentUsed, color: LifeTheme.accent)
                    .padding(.top, 4)

                HStack {
                    Text("已過 \(metrics.percentString)")
                        .font(.caption2).foregroundStyle(LifeTheme.textSecondary)  // // modified
                    Spacer()
                    Text("剩 \(Int((1-metrics.percentUsed)*100))%")
                        .font(.caption2).foregroundStyle(LifeTheme.accent)
                }

                Divider().padding(.vertical, 4)

                StatRow(label: "週剩餘", value: metrics.weeksRemaining.formatted())
                StatRow(label: "年剩餘", value: "\(metrics.yearsRemaining)")
                StatRow(label: "現在",   value: "\(metrics.ageYears) 歲")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
        .navigationTitle("人生減法")
    }
}

struct StatRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.caption2).foregroundStyle(LifeTheme.textSecondary)  // // modified
            Spacer()
            Text(value)
                .font(.system(.caption, design: .rounded)).fontWeight(.semibold)
        }
    }
}

// 共用：簡化版 ProgressLine（避免依賴主 App 的 ProgressBar）
struct ProgressLine: View {
    let value: Double
    var color: Color = LifeTheme.accent
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.10))  // // modified
                Capsule().fill(color)
                    .frame(width: geo.size.width * min(1, max(0, value)))
            }
        }
        .frame(height: 5)
    }
}
