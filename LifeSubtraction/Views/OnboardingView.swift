import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: LifeStore
    @State private var step = 0
    @State private var birthday: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
    @State private var expectancy: Int = 80

    var body: some View {
        ZStack {
            // 暗色底 + 微光暈  // modified
            LifeTheme.subtleBackground.ignoresSafeArea()

            // 兩顆 radial 微光，讓深底有呼吸感  // modified
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
                    ForEach(0..<3) { i in
                        Capsule()
                            .fill(i == step ? AnyShapeStyle(LifeTheme.heroGradient) : AnyShapeStyle(Color.white.opacity(0.20))) // // modified
                            .frame(width: i == step ? 32 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
                    }
                }
                .padding(.top, 60)

                Spacer()

                Group {
                    if step == 0 { stepZero }
                    else if step == 1 { stepOne }
                    else { stepTwo }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()

                PrimaryButton(step == 2 ? "開始我的人生減法" : "繼續", action: nextStep) // // modified
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
                    .shadow(color: LifeTheme.accent.opacity(0.35), radius: 30) // // modified — glow
                Image(systemName: "hourglass")
                    .font(.system(size: 56))
                    .foregroundStyle(LifeTheme.accent)
            }
            Text("人生減法")
                .font(.largeTitle).fontWeight(.bold)
                .foregroundStyle(LifeTheme.textPrimary)                    // // modified
            Text("每一天都是珍貴的。\n當你看見剩餘的時間，\n才能真正決定什麼值得。")
                .font(.body)
                .foregroundStyle(LifeTheme.textSecondary)                  // // modified
                .multilineTextAlignment(.center)
                .lineSpacing(6)
        }
        .padding(.horizontal, 32)
    }

    var stepOne: some View {
        VStack(spacing: 24) {
            Text("你的生日是？")
                .font(.title2).fontWeight(.bold)
                .foregroundStyle(LifeTheme.textPrimary)                    // // modified
            DatePicker("", selection: $birthday, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "zh_TW"))
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(LifeTheme.glassFill)                          // // modified
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
                )
        }
        .padding(.horizontal, 20)
    }

    var stepTwo: some View {
        VStack(spacing: 24) {
            Text("預計壽命")
                .font(.title2).fontWeight(.bold)
                .foregroundStyle(LifeTheme.textPrimary)                    // // modified
            Text("\(expectancy) 歲")
                .font(.system(size: 64, weight: .light, design: .rounded))
                .foregroundStyle(LifeTheme.accent)
            Slider(value: Binding(
                get: { Double(expectancy) },
                set: { expectancy = Int($0) }
            ), in: 60...110, step: 1)
            .tint(LifeTheme.accent)
            .padding(.horizontal, 32)
            Text("台灣平均壽命約 80 歲，健康生活可達 85-90 歲")
                .font(.caption)
                .foregroundStyle(LifeTheme.textTertiary)                   // // modified
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }

    func nextStep() {
        if step < 2 {
            withAnimation { step += 1 }
        } else {
            store.birthday = birthday
            store.lifeExpectancy = expectancy
            NotificationManager.shared.scheduleDailyReminder()
            withAnimation { store.hasCompletedOnboarding = true }
        }
    }
}
