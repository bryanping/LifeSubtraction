import SwiftUI

struct WatchYearProgressView: View {
    let metrics: LifeMetrics

    var body: some View {
        VStack(spacing: 6) {
            Text("這一年")
                .font(.caption2).foregroundStyle(LifeTheme.textSecondary)  // // modified

            // 環狀進度條
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.25), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: metrics.progressOfCurrentYear)
                    .stroke(
                        AngularGradient(
                            colors: [LifeTheme.warm, LifeTheme.warm.opacity(0.6)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(metrics.ageYears)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("歲")
                        .font(.caption2).foregroundStyle(LifeTheme.textSecondary)  // // modified
                }
            }
            .frame(width: 110, height: 110)

            Text("本年已過 \(Int(metrics.progressOfCurrentYear * 100))%")
                .font(.caption2).foregroundStyle(LifeTheme.textSecondary)  // // modified
        }
        .navigationTitle("年進度")
    }
}
