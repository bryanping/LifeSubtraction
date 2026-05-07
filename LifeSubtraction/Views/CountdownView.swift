import SwiftUI

struct CountdownView: View {
    @EnvironmentObject var store: LifeStore
    @State private var reflectionText = ""
    @State private var saved = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    bigCountdown
                        .padding(.horizontal)

                    breakdownRow
                        .padding(.horizontal)

                    reflectionCard
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                }
                .padding(.vertical, 8)
            }
            .scrollContentBackground(.hidden)                              // // modified
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("倒數")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)               // // modified
            .onAppear(perform: loadTodayReflection)
        }
    }

    // MARK: - Big countdown  // modified

    var bigCountdown: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LifeTheme.heroGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 0.5) // // modified
                )

            VStack(spacing: 4) {
                Text("距離 \(store.lifeExpectancy) 歲還有")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.85))            // // modified
                Text(store.daysRemaining.formatted())
                    .font(.system(size: 88, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(Color.white)                          // // modified
                Text("天")
                    .font(.title2)
                    .foregroundStyle(Color.white.opacity(0.85))            // // modified
                    .padding(.top, -10)
            }
            .padding(.vertical, 28)
        }
        .shadow(color: LifeTheme.accent.opacity(0.20), radius: 20, y: 10)  // // modified
    }

    // MARK: - Breakdown  // modified

    var breakdownRow: some View {
        HStack(spacing: 0) {
            breakdownItem(value: store.daysRemaining / 365, unit: "年")
            verticalDivider
            breakdownItem(value: (store.daysRemaining % 365) / 30, unit: "月")
            verticalDivider
            breakdownItem(value: store.daysRemaining % 30, unit: "天")
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LifeTheme.glassFill)                                  // // modified
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(LifeTheme.glassBorder, lineWidth: 0.5)              // // modified
        )
    }

    var verticalDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))                                // // modified
            .frame(width: 0.5, height: 50)
    }

    func breakdownItem(value: Int, unit: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 32, weight: .light, design: .rounded))
                .foregroundStyle(LifeTheme.accent)
            Text(unit)
                .font(.caption)
                .foregroundStyle(LifeTheme.textSecondary)                   // // modified
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    // MARK: - Reflection  // modified

    var reflectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(LifeTheme.accent)
                Text("今日反思")
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)                 // // modified
                Spacer()
            }

            Text("今天，你做了什麼讓未來的你感謝的事？")
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)                   // // modified

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.04))                        // // modified
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                    )
                TextEditor(text: $reflectionText)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(minHeight: 130)
                    .foregroundStyle(LifeTheme.textPrimary)                 // // modified
            }

            // 改用 PrimaryButton  // modified
            if saved {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("已儲存今日反思")
                    }
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(LifeTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.white.opacity(0.06)))
                }
                .disabled(true)
            } else {
                PrimaryButton("儲存今日反思", icon: "square.and.arrow.down", action: saveReflection)
            }
        }
        .cardStyle()
    }

    func todayKey() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return "reflection-\(f.string(from: Date()))"
    }

    func loadTodayReflection() {
        reflectionText = UserDefaults.shared.string(forKey: todayKey()) ?? ""
    }

    func saveReflection() {
        UserDefaults.shared.set(reflectionText, forKey: todayKey())
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { saved = false }
        }
    }
}
