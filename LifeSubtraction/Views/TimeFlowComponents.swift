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

// MARK: - Countdown Time Flow

enum TimeFlowUnit: String, CaseIterable, Identifiable {
    case year, month, week, day, hour, minute, second

    var id: String { rawValue }

    var title: String {
        switch self {
        case .year:   return "年"
        case .month:  return "月"
        case .week:   return "週"
        case .day:    return "日"
        case .hour:   return "時"
        case .minute: return "分"
        case .second: return "秒"
        }
    }

    func displayText(metrics: LifeMetrics) -> String {
        switch self {
        case .year:
            return String(format: "%.4f 年", metrics.yearsRemainingPrecise)
        case .month:
            return String(format: "%.3f 月", metrics.monthsRemainingPrecise)
        case .week:
            return String(format: "%.2f 週", metrics.weeksRemainingPrecise)
        case .day:
            return "\(metrics.daysRemaining.formatted()) 天"
        case .hour:
            return String(format: "%.1f 小時", metrics.hoursRemaining)
        case .minute:
            return String(format: "%.0f 分", metrics.minutesRemaining)
        case .second:
            return "\(Int(metrics.secondsRemaining).formatted())"
        }
    }

    var tickInterval: TimeInterval {
        switch self {
        case .second: return 1
        case .minute: return 1
        default:      return 0.25
        }
    }
}

struct FlipSecondsDisplay: View {
    let value: Int

    var body: some View {
        Text(value.formatted(.number.grouping(.automatic)))
            .font(.system(size: 34, weight: .light, design: .rounded))
            .foregroundStyle(LifeTheme.warm)
            .monospacedDigit()
            .contentTransition(.numericText())
            .animation(.snappy(duration: 0.35), value: value)
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
