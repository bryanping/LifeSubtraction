import SwiftUI

struct WatchWeekProgressView: View {
    let metrics: LifeMetrics

    var body: some View {
        VStack(spacing: 8) {
            Text("這一週")
                .font(.caption2).foregroundStyle(LifeTheme.textSecondary)  // // modified

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.25), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: metrics.progressOfCurrentWeek)
                    .stroke(
                        AngularGradient(
                            colors: [LifeTheme.accent, LifeTheme.accent.opacity(0.6)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(metrics.weeksLived + 1)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                    Text("/\(metrics.totalWeeks)")
                        .font(.caption2).foregroundStyle(LifeTheme.textSecondary)  // // modified
                }
            }
            .frame(width: 110, height: 110)

            Text("本週已過 \(Int(metrics.progressOfCurrentWeek * 100))%")
                .font(.caption2).foregroundStyle(LifeTheme.textSecondary)  // // modified
        }
        .navigationTitle("週進度")
    }
}
