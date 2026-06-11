import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: LifeStore
    @State private var step = 0
    @State private var birthday: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
    @State private var expectancy: Int = 80
    @State private var questionnaireRates: [JourneyQuestionTemplate: Double] = [
        .reading: 1,
        .familyTime: 2,
        .travel: 1
    ]

    var body: some View {
        ZStack {
            LifeTheme.subtleBackground.ignoresSafeArea()

            RadialGradient(
                colors: [LifeTheme.accent.opacity(0.18), .clear],
                center: .topLeading, startRadius: 0, endRadius: 500
            )
            .ignoresSafeArea()
            RadialGradient(
                colors: [LifeTheme.accentEnd.opacity(0.16), .clear],
                center: .bottomTrailing, startRadius: 0, endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    ForEach(0..<4) { i in
                        Capsule()
                            .fill(i == step ? AnyShapeStyle(LifeTheme.heroGradient) : AnyShapeStyle(Color.white.opacity(0.20)))
                            .frame(width: i == step ? 32 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
                    }
                }
                .padding(.top, 60)

                Spacer()

                Group {
                    switch step {
                    case 0: stepZero
                    case 1: stepOne
                    case 2: stepTwo
                    default: stepQuestionnaire
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()

                PrimaryButton(step == 3 ? "開始我的人生減法" : "繼續", action: nextStep)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.dark)
    }

    var stepZero: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(LifeTheme.accentSoft)
                    .frame(width: 120, height: 120)
                    .shadow(color: LifeTheme.accent.opacity(0.35), radius: 30)
                Image(systemName: "hourglass")
                    .font(.system(size: 56))
                    .foregroundStyle(LifeTheme.accent)
            }
            Text("人生減法")
                .font(.largeTitle.bold())
                .foregroundStyle(LifeTheme.textPrimary)
            Text("每一天都是珍貴的。\n當你看見剩餘的時間，\n才能真正決定什麼值得。")
                .font(.body)
                .foregroundStyle(LifeTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
        }
        .padding(.horizontal, 32)
    }

    var stepOne: some View {
        VStack(spacing: 24) {
            Text("你的生日是？")
                .font(.title2.bold())
                .foregroundStyle(LifeTheme.textPrimary)
            DatePicker("", selection: $birthday, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "zh_TW"))
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(LifeTheme.glassFill))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(LifeTheme.glassBorder, lineWidth: 0.5))
        }
        .padding(.horizontal, 20)
    }

    var stepTwo: some View {
        VStack(spacing: 24) {
            Text("預計壽命")
                .font(.title2.bold())
                .foregroundStyle(LifeTheme.textPrimary)
            Text("\(expectancy) 歲")
                .font(.system(size: 64, weight: .light, design: .rounded))
                .foregroundStyle(LifeTheme.accent)
            Slider(
                value: Binding(get: { Double(expectancy) }, set: { expectancy = Int($0) }),
                in: 60...110,
                step: 1
            )
            .tint(LifeTheme.accent)
            .padding(.horizontal, 32)
            Text("台灣平均壽命約 80 歲，健康生活可達 85–90 歲")
                .font(.caption)
                .foregroundStyle(LifeTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }

    var stepQuestionnaire: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("你的生活節奏")
                    .font(.title2.bold())
                    .foregroundStyle(LifeTheme.textPrimary)
                Text("這些問題用來估算過去的累積，之後可用紀錄慢慢校正。")
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textSecondary)

                ForEach(JourneyQuestionTemplate.allCases) { template in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(template.question)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(LifeTheme.textPrimary)
                        Slider(
                            value: Binding(
                                get: { questionnaireRates[template] ?? 0 },
                                set: { questionnaireRates[template] = $0 }
                            ),
                            in: 0...12,
                            step: template == .travel ? 1 : 0.5
                        )
                        .tint(LifeTheme.accent)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 16).fill(LifeTheme.glassFill))
                }
            }
            .padding(.horizontal, 24)
        }
    }

    func nextStep() {
        if step < 3 {
            withAnimation { step += 1 }
        } else {
            store.birthday = birthday
            store.lifeExpectancy = expectancy

            let result = JourneyStatsBootstrap.applyQuestionnaire(
                rates: questionnaireRates,
                ageYears: store.ageYears
            )
            LocalJSONStore.save(result.stats, key: StorageKey.lifeJourneyStatItems)
            LocalJSONStore.save(result.moments, key: StorageKey.remainingMomentItems)
            LocalJSONStore.save([LifeJourneyStatRecord](), key: StorageKey.lifeJourneyStatRecords)

            NotificationManager.shared.scheduleDailyReminder()
            withAnimation { store.hasCompletedOnboarding = true }
        }
    }
}
