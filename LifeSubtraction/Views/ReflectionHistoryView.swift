import SwiftUI

struct ReflectionHistoryView: View {
    @State private var reflections: [ReflectionEntry] = []
    @State private var filterPeriod: ReflectionPeriod?

    private var filteredReflections: [ReflectionEntry] {
        let sorted = reflections.sorted { $0.date > $1.date }
        guard let filterPeriod else { return sorted }
        return sorted.filter { $0.period == filterPeriod }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LifeTheme.subtleBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Picker("篩選", selection: $filterPeriod) {
                            Text("全部").tag(Optional<ReflectionPeriod>.none)
                            ForEach(ReflectionPeriod.allCases) { period in
                                Text(period.displayName).tag(Optional(period))
                            }
                        }
                        .pickerStyle(.segmented)

                        if filteredReflections.isEmpty {
                            emptyState
                        } else {
                            ForEach(filteredReflections) { reflection in
                                reflectionRow(reflection)
                            }
                        }
                    }
                    .padding()
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("反思紀錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear(perform: loadReflections)
        }
        .preferredColorScheme(.dark)
    }

    private var emptyState: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "text.book.closed.fill")
                .font(.system(size: 40))
                .foregroundStyle(LifeTheme.textTertiary)
            Text("還沒有反思紀錄")
                .font(.headline)
                .foregroundStyle(LifeTheme.textPrimary)
            Text("從單日或每週開始寫下你的想法")
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func reflectionRow(_ reflection: ReflectionEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                periodBadge(reflection.period)
                Text(dateTitle(for: reflection))
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)
                Spacer()
                Text(reflection.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textTertiary)
            }

            Text(reflection.text)
                .font(.body)
                .foregroundStyle(LifeTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LifeTheme.glassFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
        )
    }

    private func periodBadge(_ period: ReflectionPeriod) -> some View {
        Text(period.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(period == .daily ? LifeTheme.accent : LifeTheme.warm)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(period == .daily ? LifeTheme.accentSoft : LifeTheme.warmSoft)
            )
    }

    private func dateTitle(for reflection: ReflectionEntry) -> String {
        switch reflection.period {
        case .daily:
            return reflection.date.formatted(date: .abbreviated, time: .omitted)
        case .weekly:
            let cal = Calendar.current
            let year = cal.component(.yearForWeekOfYear, from: reflection.date)
            let week = cal.component(.weekOfYear, from: reflection.date)
            return "\(year) 年第 \(week) 週"
        }
    }

    private func loadReflections() {
        reflections = LocalJSONStore.load(
            [ReflectionEntry].self,
            key: ReflectionEntry.storageKey,
            defaultValue: []
        )
    }
}

#Preview {
    ReflectionHistoryView()
}
