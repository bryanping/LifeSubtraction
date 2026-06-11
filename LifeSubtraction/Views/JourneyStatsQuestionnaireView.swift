import SwiftUI

struct JourneyStatsQuestionnaireView: View {
    @EnvironmentObject var store: LifeStore
    @Environment(\.dismiss) private var dismiss

    @State private var rates: [JourneyQuestionTemplate: Double] = [
        .reading: 1,
        .familyTime: 2,
        .travel: 1
    ]

    var onComplete: (([LifeJourneyStatItem], [RemainingMomentItem]) -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("幫我們了解你的生活節奏")
                        .font(.title2.bold())
                        .foregroundStyle(LifeTheme.textPrimary)

                    Text("這些問題只用來估算過去的累積，之後你可以用紀錄慢慢校正。")
                        .font(.subheadline)
                        .foregroundStyle(LifeTheme.textSecondary)

                    ForEach(JourneyQuestionTemplate.allCases) { template in
                        questionCard(template)
                    }

                    PrimaryButton("建立我的累積項目", icon: "sparkles") {
                        finish()
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("人生累積")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    func questionCard(_ template: JourneyQuestionTemplate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: template.iconName)
                    .foregroundStyle(LifeTheme.accent)
                Text(template.question)
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)
            }

            HStack {
                Slider(
                    value: Binding(
                        get: { rates[template] ?? 0 },
                        set: { rates[template] = $0 }
                    ),
                    in: 0...12,
                    step: template == .travel ? 1 : 0.5
                )
                .tint(LifeTheme.accent)

                Text(rateLabel(template))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(LifeTheme.accent)
                    .frame(width: 56, alignment: .trailing)
            }

            Text("估算過去累積約 \(template.baselineEstimate(ageYears: store.ageYears, rate: rates[template] ?? 0)) \(template.unit)")
                .font(.caption)
                .foregroundStyle(LifeTheme.textTertiary)
        }
        .cardStyle()
    }

    func rateLabel(_ template: JourneyQuestionTemplate) -> String {
        let value = rates[template] ?? 0
        if template == .travel {
            return "\(Int(value))"
        }
        return value.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(value))"
            : String(format: "%.1f", value)
    }

    func finish() {
        let result = JourneyStatsBootstrap.applyQuestionnaire(
            rates: rates,
            ageYears: store.ageYears
        )
        onComplete?(result.stats, result.moments)
        dismiss()
    }
}

#Preview {
    JourneyStatsQuestionnaireView()
        .environmentObject(LifeStore())
}
