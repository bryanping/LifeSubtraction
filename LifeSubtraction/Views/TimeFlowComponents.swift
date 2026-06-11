import Combine
import SwiftUI

// MARK: - Overview Hero

enum OverviewHeroUnit: CaseIterable {
    case years, months, days, hours

    var label: String {
        switch self {
        case .years:  return "年"
        case .months: return "月"
        case .days:   return "天"
        case .hours:  return "小時"
        }
    }

    func valueText(metrics: LifeMetrics) -> String {
        switch self {
        case .years:
            return String(format: "%.1f", metrics.yearsRemainingPrecise)
        case .months:
            return String(format: "%.0f", metrics.monthsRemainingPrecise)
        case .days:
            return metrics.daysRemaining.formatted(.number.grouping(.automatic))
        case .hours:
            return String(format: "%.0f", metrics.hoursRemaining)
        }
    }
}

struct LifeRemainingRing: View {
    let percent: Double

    private var percentInt: Int {
        Int((percent * 100).rounded())
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 10)

            Circle()
                .trim(from: 0, to: min(1, max(0, percent)))
                .stroke(
                    LifeTheme.heroGradient,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: percent)

            VStack(spacing: 4) {
                Text("人生剩餘")
                    .font(.caption2)
                    .foregroundStyle(LifeTheme.textSecondary)
                Text("\(percentInt)%")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(LifeTheme.textPrimary)
            }
        }
    }
}

// MARK: - Countdown Time Flow（年 / 月 / 週 / 時）

enum TimeFlowUnit: CaseIterable, Identifiable, Equatable {
    case year, month, week, hour

    var id: Self { self }

    var title: String {
        switch self {
        case .year:  return "年"
        case .month: return "月"
        case .week:  return "週"
        case .hour:  return "時"
        }
    }

    var subtitle: String {
        switch self {
        case .year:  return "剩餘人生 · 年"
        case .month: return "剩餘人生 · 月"
        case .week:  return "剩餘人生 · 週"
        case .hour:  return "剩餘人生 · 時"
        }
    }

    func displayValue(metrics: LifeMetrics) -> String {
        switch self {
        case .year:
            return String(format: "%.4f", metrics.yearsRemainingPrecise)
        case .month:
            return String(format: "%.3f", metrics.monthsRemainingPrecise)
        case .week:
            return String(format: "%.2f", metrics.weeksRemainingPrecise)
        case .hour:
            return String(format: "%.1f", metrics.hoursRemaining)
        }
    }

    func next() -> TimeFlowUnit {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self) else { return .year }
        return all[(index + 1) % all.count]
    }

    func previous() -> TimeFlowUnit {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self) else { return .year }
        return all[(index + all.count - 1) % all.count]
    }
}

struct RhythmProgressRow: View {
    let title: String
    let progress: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textSecondary)
                Spacer()
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(tint)
                    .monospacedDigit()
            }
            ProgressBar(value: progress, color: tint, useGradient: false)
        }
    }
}

// MARK: - 整合：時間流動 + 時間節奏

struct IntegratedTimeFlowCard: View {
    let birthday: Date
    let lifeExpectancy: Int

    @State private var unit: TimeFlowUnit = .year
    @State private var dragOffset: CGFloat = 0
    @State private var autoTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("時間正在流動")
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textSecondary)
                Spacer()
                unitIndicator
            }

            flowValueArea

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5)

            rhythmArea
        }
        .cardStyle()
        .onReceive(autoTimer) { _ in
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                unit = unit.next()
            }
        }
    }

    private var unitIndicator: some View {
        HStack(spacing: 6) {
            ForEach(TimeFlowUnit.allCases) { item in
                Capsule()
                    .fill(item == unit ? LifeTheme.accent : Color.white.opacity(0.15))
                    .frame(width: item == unit ? 18 : 6, height: 6)
                    .animation(.spring(response: 0.35), value: unit)
            }
        }
    }

    private var flowValueArea: some View {
        TimelineView(.periodic(from: Date(), by: 0.25)) { context in
            let metrics = LifeMetrics(
                birthday: birthday,
                lifeExpectancy: lifeExpectancy,
                now: context.date
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(unit.subtitle)
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textTertiary)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(unit.displayValue(metrics: metrics))
                        .font(.system(size: 40, weight: .light, design: .rounded))
                        .foregroundStyle(LifeTheme.textPrimary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .offset(x: dragOffset * 0.15)
                        .animation(.snappy, value: unit)

                    Text(unit.title)
                        .font(.title3)
                        .foregroundStyle(LifeTheme.warm)
                }

                Text("左右滑動切換 · 每 5 秒自動輪播")
                    .font(.caption2)
                    .foregroundStyle(LifeTheme.textQuaternary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 24)
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if value.translation.width < -threshold {
                                unit = unit.next()
                            } else if value.translation.width > threshold {
                                unit = unit.previous()
                            }
                            dragOffset = 0
                        }
                    }
            )
        }
    }

    private var rhythmArea: some View {
        TimelineView(.periodic(from: Date(), by: 30)) { context in
            let metrics = LifeMetrics(
                birthday: birthday,
                lifeExpectancy: lifeExpectancy,
                now: context.date
            )

            VStack(spacing: 14) {
                RhythmProgressRow(
                    title: "本年已過",
                    progress: metrics.progressOfCurrentYear,
                    tint: LifeTheme.warm
                )
                RhythmProgressRow(
                    title: "本週已過",
                    progress: metrics.progressOfCurrentWeek,
                    tint: LifeTheme.accent
                )
                RhythmProgressRow(
                    title: "今天已過",
                    progress: metrics.progressOfCurrentDay,
                    tint: LifeTheme.accentEnd
                )

                HStack(spacing: 8) {
                    Image(systemName: "sun.horizon.fill")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.accent)
                    Text(String(format: "今天還剩 %.1f 小時", metrics.hoursRemainingToday))
                        .font(.subheadline)
                        .foregroundStyle(LifeTheme.textSecondary)
                        .monospacedDigit()
                }
            }
        }
    }
}
