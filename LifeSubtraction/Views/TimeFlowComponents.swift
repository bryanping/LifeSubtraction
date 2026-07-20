import Combine
import SwiftUI

// MARK: - Overview Hero (OverviewView 使用)

enum OverviewHeroUnit: CaseIterable {
    case lifeYears, yearMonths, monthDays, todayHours

    var label: String {
        switch self {
        case .lifeYears:  return "年"
        case .yearMonths: return "月"
        case .monthDays:  return "天"
        case .todayHours: return "時"
        }
    }

    func valueText(metrics: LifeMetrics) -> String {
        switch self {
        case .lifeYears:
            return String(format: "%.1f", metrics.yearsRemainingPrecise)
        case .yearMonths:
            let remaining = max(0, Int(ceil(Double(12 - Calendar.current.component(.month, from: metrics.now) + 1))))
            return "\(remaining)"
        case .monthDays:
            return "\(max(0, Int(ceil(metrics.daysRemainingThisMonth))))"
        case .todayHours:
            return OverviewHeroUnit.todayTimeText(metrics: metrics)
        }
    }

    func headline(metrics: LifeMetrics) -> String {
        switch self {
        case .lifeYears:
            return "人生還有"
        case .yearMonths:
            return "今年還有"
        case .monthDays:
            return "本月還有"
        case .todayHours:
            return "今日還有"
        }
    }

    func ringProgress(metrics: LifeMetrics) -> Double {
        switch self {
        case .lifeYears:
            return metrics.percentRemaining
        case .yearMonths:
            return 1 - metrics.progressOfCurrentYear
        case .monthDays:
            return 1 - metrics.progressOfCurrentMonth
        case .todayHours:
            return 1 - metrics.progressOfCurrentDay
        }
    }

    private static func todayTimeText(metrics: LifeMetrics) -> String {
        let seconds = max(0, Int(metrics.hoursRemainingToday * 3600))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}

struct LifeRemainingRing: View {
    let percent: Double
    private var percentInt: Int { Int((percent * 100).rounded()) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: 10)
            Circle()
                .trim(from: 0, to: min(1, max(0, percent)))
                .stroke(LifeTheme.heroGradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.7), value: percent)
            VStack(spacing: 3) {
                Text("剩餘")
                    .font(.caption2)
                    .foregroundStyle(LifeTheme.textSecondary)
                Text("\(percentInt)%")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(LifeTheme.textPrimary)
            }
        }
    }
}

// MARK: - 總覽碼錶（四層同心圓環 · 參考設計稿）

private struct StopwatchRingPalette {
    let active: Color
    let track: Color

    /// 外圈 · 人生（年）
    static let lifeYear = StopwatchRingPalette(
        active: LifeTheme.ringLife,
        track: Color.white.opacity(0.06)
    )
    /// 第二圈 · 月
    static let month = StopwatchRingPalette(
        active: LifeTheme.ringYear,
        track: Color.white.opacity(0.06)
    )
    /// 第三圈 · 日
    static let day = StopwatchRingPalette(
        active: LifeTheme.ringMonth,
        track: Color.white.opacity(0.06)
    )
    /// 內圈 · 時間
    static let time = StopwatchRingPalette(
        active: LifeTheme.ringDay,
        track: Color.white.opacity(0.07)
    )
}

private enum StopwatchDialStyle {
    static let tickMajor = Color.white.opacity(0.50)
    static let tickMinor = Color.white.opacity(0.17)
    static let tickLabel = Color.white.opacity(0.34)
    static let arrowGold = Color(red: 1.0, green: 0.78, blue: 0.22)
}

private enum StopwatchDialAsset {
    static let imageName = "StopwatchDial"
    /// 底圖放大係數（相對進度弧座標系）
    static let assetScale: CGFloat = 1.12
    /// 四圈統一線寬
    static let ringLineWidth: CGFloat = 14
    /// 凹槽中心線（外→內），整體收緊
    static let ringRadiusFractions: [CGFloat] = [0.820, 0.700, 0.570, 0.440]
}
private struct StopwatchLegendItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let percent: Int
    let color: Color
    let alignment: Alignment
}

struct LifeStopwatchRingsView: View {
    let birthday: Date
    let lifeExpectancy: Int

    @State private var introProgress: Double = 0

    private let dialSize: CGFloat = 290
    private var dialAssetSize: CGFloat { dialSize * StopwatchDialAsset.assetScale }
    private let frameSize: CGFloat = 330
    private let introAnimation = Animation.easeOut(duration: 0.85)

    private struct RingSpec {
        let fraction: Double
        let tickCount: Int
        let radius: CGFloat
        let lineWidth: CGFloat
        let palette: StopwatchRingPalette
        let majorLabels: [Int]?
        let useTimeGradient: Bool
    }

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 0.1)) { ctx in
            let metrics = LifeMetrics(
                birthday: birthday,
                lifeExpectancy: lifeExpectancy,
                now: ctx.date
            )
            dialContent(metrics: metrics)
        }
        .onAppear {
            introProgress = 0
            withAnimation(introAnimation) {
                introProgress = 1
            }
        }
    }

    @ViewBuilder
    private func dialContent(metrics: LifeMetrics) -> some View {
        VStack(spacing: 22) {
            ZStack {
                ForEach(legends(for: metrics)) { item in
                    StopwatchCornerLegend(item: item)
                        .frame(width: frameSize, height: frameSize, alignment: item.alignment)
                }

                ZStack {
                    Image(StopwatchDialAsset.imageName)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .frame(width: dialAssetSize, height: dialAssetSize)

                    AgeLabelOverlay(
                        dialSize: dialAssetSize,
                        expectancy: metrics.lifeExpectancy
                    )

                    ForEach(Array(rings(for: metrics).enumerated()), id: \.offset) { _, spec in
                        StopwatchRingLayer(
                            fraction: min(1, max(0, spec.fraction * introProgress)),
                            tickCount: spec.tickCount,
                            radius: spec.radius,
                            lineWidth: spec.lineWidth,
                            palette: spec.palette,
                            majorLabels: spec.majorLabels,
                            useTimeGradient: spec.useTimeGradient,
                            dialSize: dialAssetSize,
                            showsTrack: false,
                            showsTicks: false
                        )
                    }

                    StopwatchMiniClockHands(
                        hourAngle: clockHandAngles(for: metrics).hour,
                        minuteAngle: clockHandAngles(for: metrics).minute,
                        minRadius: centerHubRadius + 2,
                        handBandLength: handBandLength(for: metrics)
                    )
                    .frame(width: dialAssetSize, height: dialAssetSize)

                    centerPercentLabel(for: metrics)
                }
                .frame(width: dialAssetSize, height: dialAssetSize)
            }
            .frame(width: frameSize, height: frameSize)

            timecodeBlock(metrics: metrics)
        }
        .frame(maxWidth: .infinity)
    }

    private func centerPercent(for metrics: LifeMetrics) -> Int {
        Int((metrics.lifeRemainingFraction * introProgress * 100).rounded())
    }

    private func clockHandAngles(for metrics: LifeMetrics) -> (hour: Double, minute: Double) {
        let cal = Calendar.current
        let h = cal.component(.hour, from: metrics.now)
        let m = cal.component(.minute, from: metrics.now)
        let s = cal.component(.second, from: metrics.now)
        let minute = (Double(m) + Double(s) / 60) / 60 * 360 - 90
        let hour = (Double(h % 12) + Double(m) / 60 + Double(s) / 3600) / 12 * 360 - 90
        return (hour, minute)
    }

    private let centerHubRadius: CGFloat = 40

    private func handBandLength(for metrics: LifeMetrics) -> CGFloat {
        max(12, innerRingInnerRadius(for: metrics) - centerHubRadius - 6)
    }

    private func innerRingInnerRadius(for metrics: LifeMetrics) -> CGFloat {
        guard let inner = rings(for: metrics).last else { return centerHubRadius + 30 }
        return inner.radius - inner.lineWidth / 2
    }

    private func rings(for metrics: LifeMetrics) -> [RingSpec] {
        let expectancy = max(1, metrics.lifeExpectancy)
        let ageLabels = [0, expectancy / 4, expectancy / 2, expectancy * 3 / 4]

        let configs: [(Double, Int, StopwatchRingPalette, [Int]?, Bool)] = [
            (metrics.lifeRemainingFraction, min(100, expectancy), .lifeYear, ageLabels, false),
            (metrics.lifeMonthsRingFraction, 12, .month, [0, 3, 6, 9], false),
            (metrics.lifeDaysRingFraction, 31, .day, nil, false),
            (metrics.todayHoursRingFraction, 24, .time, [0, 6, 12, 18], true),
        ]

        let half = dialAssetSize / 2
        let lineWidth = StopwatchDialAsset.ringLineWidth
        return zip(configs, StopwatchDialAsset.ringRadiusFractions).map { config, radiusFraction in
            RingSpec(
                fraction: config.0,
                tickCount: config.1,
                radius: half * radiusFraction,
                lineWidth: lineWidth,
                palette: config.2,
                majorLabels: config.3,
                useTimeGradient: config.4
            )
        }
    }

    private func legends(for metrics: LifeMetrics) -> [StopwatchLegendItem] {
        [
            StopwatchLegendItem(
                id: "year",
                title: "人生",
                subtitle: "(年)",
                percent: centerPercent(for: metrics),
                color: LifeTheme.ringLife,
                alignment: .topLeading
            ),
            StopwatchLegendItem(
                id: "month",
                title: "月",
                subtitle: nil,
                percent: Int((metrics.lifeMonthsRingFraction * introProgress * 100).rounded()),
                color: LifeTheme.ringYear,
                alignment: .topTrailing
            ),
            StopwatchLegendItem(
                id: "day",
                title: "日",
                subtitle: nil,
                percent: Int((metrics.lifeDaysRingFraction * introProgress * 100).rounded()),
                color: LifeTheme.ringMonth,
                alignment: .bottomLeading
            ),
            StopwatchLegendItem(
                id: "time",
                title: "時間",
                subtitle: nil,
                percent: Int((metrics.todayHoursRingFraction * introProgress * 100).rounded()),
                color: LifeTheme.ringDay,
                alignment: .bottomTrailing
            ),
        ]
    }

    private func timecodeBlock(metrics: LifeMetrics) -> some View {
        let d = metrics.lifeDateComponents
        let t = metrics.todayTimeComponents
        return VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("✦")
                    .font(.caption2)
                    .foregroundStyle(LifeTheme.textQuaternary)
                Text("人生還有")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LifeTheme.textTertiary)
                    .tracking(1.5)
                Text("✦")
                    .font(.caption2)
                    .foregroundStyle(LifeTheme.textQuaternary)
            }

            timecodeReadout(d: d, t: t)
        }
    }

    private enum TimecodeStyle {
        static let digitFont = Font.system(size: 42, weight: .bold, design: .monospaced)
        static let unitFont = Font.system(size: 10, weight: .medium)
    }

    /// 單行 Text 拼接：整段等比縮放，避免 HStack 各段獨立縮小
    private func timecodeReadout(
        d: (years: Int, months: Int, days: Int),
        t: (hours: Int, minutes: Int, seconds: Int, tenth: Int)
    ) -> some View {
        let timeString = String(format: "%02d:%02d:%02d.%d", t.hours, t.minutes, t.seconds, t.tenth)

        return VStack(spacing: 5) {
            (Text(String(format: "%02d", d.years)).foregroundStyle(LifeTheme.ringLife)
             + Text(".").foregroundStyle(LifeTheme.textQuaternary)
             + Text(String(format: "%02d", d.months)).foregroundStyle(LifeTheme.ringYear)
             + Text(".").foregroundStyle(LifeTheme.textQuaternary)
             + Text(String(format: "%02d", d.days)).foregroundStyle(LifeTheme.ringMonth)
             + Text(".").foregroundStyle(LifeTheme.textQuaternary)
             + Text(timeString).foregroundStyle(LifeTheme.ringTimeGradient))
                .font(TimecodeStyle.digitFont)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            timecodeUnitRow
        }
    }

    private var timecodeUnitRow: some View {
        HStack(spacing: 0) {
            timecodeUnitLabel("年", width: 40)
            timecodeUnitSpacer(width: 12)
            timecodeUnitLabel("月", width: 40)
            timecodeUnitSpacer(width: 12)
            timecodeUnitLabel("日", width: 40)
            timecodeUnitSpacer(width: 15)
            timecodeUnitLabel("時", width: 36)
            timecodeUnitSpacer(width: 10)
            timecodeUnitLabel("分", width: 36)
            timecodeUnitSpacer(width: 10)
            timecodeUnitLabel("秒", width: 36)
            timecodeUnitSpacer(width: 36)
        }
        .font(TimecodeStyle.unitFont)
        .foregroundStyle(LifeTheme.textQuaternary)
    }

    private func timecodeUnitLabel(_ label: String, width: CGFloat) -> some View {
        Text(label)
            .frame(width: width, alignment: .center)
    }

    private func timecodeUnitSpacer(width: CGFloat) -> some View {
        Color.clear.frame(width: width, height: 1)
    }

    private func centerPercentLabel(for metrics: LifeMetrics) -> some View {
        Text("\(centerPercent(for: metrics))%")
            .font(.system(size: 38, weight: .medium, design: .rounded))
            .foregroundStyle(LifeTheme.textPrimary)
            .monospacedDigit()
            .contentTransition(.numericText(countsDown: true))
            .animation(introAnimation, value: introProgress)
    }
}

/// 四角圖例：色點 + 標題 + 百分比
private struct StopwatchCornerLegend: View {
    let item: StopwatchLegendItem

    var body: some View {
        VStack(alignment: horizontalAlignment, spacing: 3) {
            HStack(spacing: 5) {
                if item.alignment == .topTrailing || item.alignment == .bottomTrailing {
                    legendText
                    colorDot
                } else {
                    colorDot
                    legendText
                }
            }
            Text("\(item.percent)%")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(item.color)
                .monospacedDigit()
        }
        .padding(4)
    }

    private var colorDot: some View {
        Circle()
            .fill(item.color)
            .frame(width: 7, height: 7)
            .shadow(color: item.color.opacity(0.5), radius: 3)
    }

    private var legendText: some View {
        HStack(spacing: 2) {
            Text(item.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(LifeTheme.textSecondary)
            if let sub = item.subtitle {
                Text(sub)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(LifeTheme.textTertiary)
            }
        }
    }

    private var horizontalAlignment: HorizontalAlignment {
        switch item.alignment {
        case .topLeading, .bottomLeading: return .leading
        case .topTrailing, .bottomTrailing: return .trailing
        default: return .center
        }
    }
}

/// 外圈年齡標籤（虛線圓由素材提供）
private struct AgeLabelOverlay: View {
    let dialSize: CGFloat
    let expectancy: Int

    private var scaleRadius: CGFloat { dialSize / 2 * 0.90 }

    var body: some View {
        ZStack {
            ForEach(Array(ageMarkers.enumerated()), id: \.offset) { _, marker in
                let rad = marker.angle * .pi / 180
                let labelR = scaleRadius + 20
                Text(marker.label)
                    .font(.system(size: 9, weight: .regular, design: .rounded))
                    .foregroundStyle(StopwatchDialStyle.tickLabel)
                    .position(
                        x: dialSize / 2 + CGFloat(cos(rad)) * labelR,
                        y: dialSize / 2 + CGFloat(sin(rad)) * labelR
                    )
            }
        }
        .frame(width: dialSize, height: dialSize)
        .allowsHitTesting(false)
    }

    private var ageMarkers: [(label: String, angle: Double)] {
        let e = max(1, expectancy)
        let q1 = e / 4
        let q2 = e / 2
        let q3 = e * 3 / 4
        return [
            ("0", -90),
            ("\(q1) 歲", 180),
            ("\(q2) 歲", 90),
            ("\(q3) 歲", 0),
        ]
    }
}

/// 內圈與百分比數字之間的 12 進制時針（寬方）與分針（細方）
private struct StopwatchMiniClockHands: View {
    let hourAngle: Double
    let minuteAngle: Double
    let minRadius: CGFloat
    let handBandLength: CGFloat

    var body: some View {
        ZStack {
            RectClockHand(
                angle: minuteAngle,
                length: handBandLength * 0.92,
                width: 2,
                minRadius: minRadius,
                color: Color.white.opacity(0.72)
            )
            RectClockHand(
                angle: hourAngle,
                length: handBandLength * 0.62,
                width: 5.5,
                minRadius: minRadius,
                color: Color.white.opacity(0.95)
            )
        }
    }
}

private struct RectClockHand: View {
    let angle: Double
    let length: CGFloat
    let width: CGFloat
    let minRadius: CGFloat
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: width * 0.15, style: .continuous)
            .fill(color)
            .frame(width: width, height: length)
            .offset(y: -(minRadius + length / 2))
            .rotationEffect(.degrees(angle))
            .animation(.linear(duration: 0.2), value: angle)
    }
}

private struct StopwatchRingLayer: View {
    let fraction: Double
    let tickCount: Int
    let radius: CGFloat
    let lineWidth: CGFloat
    let palette: StopwatchRingPalette
    let majorLabels: [Int]?
    let useTimeGradient: Bool
    let dialSize: CGFloat
    var showsTrack: Bool = true
    var showsTicks: Bool = true

    private var inset: CGFloat { (dialSize / 2) - radius - lineWidth / 2 }

    var body: some View {
        ZStack {
            if showsTrack {
                Circle()
                    .inset(by: inset)
                    .stroke(palette.track, lineWidth: lineWidth)
            }

            progressArc

            if showsTicks {
                RingTickOverlay(
                    tickCount: tickCount,
                    radius: radius,
                    lineWidth: lineWidth,
                    majorLabels: majorLabels,
                    dialSize: dialSize
                )
            }
        }
    }

    private var progressArc: some View {
        Circle()
            .inset(by: inset)
            .trim(from: 0, to: min(1, max(0, fraction)))
            .stroke(
                progressStrokeStyle,
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .butt,
                    lineJoin: .miter
                )
            )
            .rotationEffect(.degrees(-90))
            .shadow(color: palette.active.opacity(0.22), radius: 2)
    }

    private var progressStrokeStyle: AnyShapeStyle {
        if useTimeGradient {
            AnyShapeStyle(
                AngularGradient(
                    colors: [LifeTheme.ringDay, LifeTheme.ringTimeEnd, LifeTheme.ringDay],
                    center: .center,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(270)
                )
            )
        } else {
            AnyShapeStyle(palette.active)
        }
    }
}

/// 極座標刻度：iPhone 碼表風格中性白線
private struct RingTickOverlay: View {
    let tickCount: Int
    let radius: CGFloat
    let lineWidth: CGFloat
    let majorLabels: [Int]?
    let dialSize: CGFloat

    private var majorEvery: Int {
        let safe = max(1, tickCount)
        if tickCount == 100 { return 10 }
        if tickCount == 24 { return 6 }
        if tickCount == 12 { return 3 }
        if safe >= 28 { return 7 }
        return max(1, safe / 4)
    }

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let safeCount = max(1, tickCount)
            let outerR = radius + lineWidth / 2
            let innerR = radius - lineWidth / 2

            for i in 0..<safeCount {
                let angleDeg = (Double(i) / Double(safeCount)) * 360 - 90
                let rad = angleDeg * .pi / 180
                let isMajor = i % majorEvery == 0
                // 主刻度向外延伸較長，細刻度短而密（參考 iPhone 碼表）
                let tickOuter = outerR + (isMajor ? 7 : 3)
                let tickInner = isMajor ? (innerR + lineWidth * 0.15) : (outerR - lineWidth * 0.35)

                var path = Path()
                path.move(to: CGPoint(
                    x: center.x + CGFloat(cos(rad)) * tickInner,
                    y: center.y + CGFloat(sin(rad)) * tickInner
                ))
                path.addLine(to: CGPoint(
                    x: center.x + CGFloat(cos(rad)) * tickOuter,
                    y: center.y + CGFloat(sin(rad)) * tickOuter
                ))
                context.stroke(
                    path,
                    with: .color(isMajor ? StopwatchDialStyle.tickMajor : StopwatchDialStyle.tickMinor),
                    style: StrokeStyle(
                        lineWidth: isMajor ? 1.0 : 0.45,
                        lineCap: .round
                    )
                )
            }
        }
        .frame(width: dialSize, height: dialSize)
        .overlay {
            if let labels = majorLabels {
                ringNumberLabels(labels)
            }
        }
    }

    private func ringNumberLabels(_ labels: [Int]) -> some View {
        let positions: [Double] = [-90, 0, 90, 180]
        let labelR = radius + lineWidth / 2 + 16
        let display = labels.count == 4 ? labels : labels + Array(repeating: 0, count: max(0, 4 - labels.count))

        return ZStack {
            ForEach(0..<min(4, display.count), id: \.self) { index in
                let rad = positions[index] * .pi / 180
                Text("\(display[index])")
                    .font(.system(size: 9, weight: .regular, design: .rounded))
                    .foregroundStyle(StopwatchDialStyle.tickLabel)
                    .position(
                        x: dialSize / 2 + CGFloat(cos(rad)) * labelR,
                        y: dialSize / 2 + CGFloat(sin(rad)) * labelR
                    )
            }
        }
        .frame(width: dialSize, height: dialSize)
    }
}

struct MarqueeText: View {
    let text: String
    var font: Font = .caption
    var color: Color = LifeTheme.textTertiary

    @State private var animate = false

    var body: some View {
        GeometryReader { proxy in
            Text(text)
                .font(font)
                .foregroundStyle(color)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .offset(x: animate ? -max(0, proxy.size.width * 0.75) : proxy.size.width * 0.12)
                .onAppear {
                    animate = false
                    withAnimation(.linear(duration: 9).repeatForever(autoreverses: false)) {
                        animate = true
                    }
                }
        }
        .clipped()
        .frame(height: 18)
    }
}

struct RhythmProgressRow: View {
    let title: String
    let progress: Double
    let tint: Color
    var trailingText: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.subheadline).foregroundStyle(LifeTheme.textSecondary)
                Spacer()
                Text(trailingText ?? "\(Int((progress * 100).rounded()))%")
                    .font(.subheadline.weight(.medium)).foregroundStyle(tint).monospacedDigit()
            }
            ProgressBar(value: progress, color: tint, useGradient: false)
        }
    }
}

// MARK: - TimeFlow Hero（時間頁頭部，與總覽頁一致）

enum TimeFlowHeroUnit: CaseIterable {
    case yearDays, monthDays, todayTime

    var headline: String {
        switch self {
        case .yearDays:  return "今年還剩（天）"
        case .monthDays: return "本月還剩（天）"
        case .todayTime: return "今日還剩（小時）"
        }
    }

    func valueText(metrics: LifeMetrics) -> String {
        switch self {
        case .yearDays:
            return String(format: "%.4f天", metrics.daysRemainingThisYear)
        case .monthDays:
            return String(format: "%.4f天", metrics.daysRemainingThisMonth)
        case .todayTime:
            return Self.todayCountdownText(metrics: metrics)
        }
    }

    func ringProgress(metrics: LifeMetrics) -> Double {
        switch self {
        case .yearDays:  return 1 - metrics.progressOfCurrentYear
        case .monthDays: return 1 - metrics.progressOfCurrentMonth
        case .todayTime: return 1 - metrics.progressOfCurrentDay
        }
    }

    var timeFlowUnit: TimeFlowUnit {
        switch self {
        case .yearDays:  return .year
        case .monthDays: return .month
        case .todayTime: return .hour
        }
    }

    var tickInterval: TimeInterval {
        self == .todayTime ? 1 : 0.25
    }

    var valueFontSize: CGFloat {
        self == .todayTime ? 28 : 32
    }

    var recommendationScope: TimeRecommendationScope {
        switch self {
        case .yearDays: return .year
        case .monthDays: return .month
        case .todayTime: return .today
        }
    }

    private static func todayCountdownText(metrics: LifeMetrics) -> String {
        let total = max(0, metrics.hoursRemainingToday * 3600)
        let h = Int(total) / 3600
        let m = (Int(total) % 3600) / 60
        let secPart = total - Double(h * 3600 + m * 60)
        let secBlock = min(9999, Int(secPart * 100))
        return String(format: "%02d:%02d:%04d", h, m, secBlock)
    }
}

// MARK: - TimeFlowUnit（5個單位）

// 修改内容 — 移除分、秒；時 = 今日剩餘倒數
enum TimeFlowUnit: CaseIterable, Identifiable, Equatable {
    case year, month, week, day, hour

    var id: Self { self }

    var title: String {
        switch self {
        case .year:  return "年"
        case .month: return "月"
        case .week:  return "週"
        case .day:   return "日"
        case .hour:  return "時"
        }
    }

    var description: String {
        switch self {
        case .year:  return "剩餘年份"
        case .month: return "剩餘月數"
        case .week:  return "剩餘週數"
        case .day:   return "剩餘天數"
        case .hour:  return "今日剩餘"   // 修改内容 — 今日倒數
        }
    }

    // 修改内容 — 時 = 今日剩餘小時，每秒更新
    var tickInterval: TimeInterval { self == .hour ? 1 : 0.25 }

    func displayValue(metrics: LifeMetrics) -> String {
        switch self {
        case .year:  return String(format: "%.4f", metrics.yearsRemainingPrecise)
        case .month: return String(format: "%.3f", metrics.monthsRemainingPrecise)
        case .week:  return String(format: "%.2f", metrics.weeksRemainingPrecise)
        case .day:   return metrics.daysRemaining.formatted(.number.grouping(.automatic))
        case .hour:  return String(format: "%.2f", metrics.hoursRemainingToday) // 修改内容
        }
    }

    // 修改内容 — 對應推薦目標分類
    var recommendedDuration: GoalDurationClass {
        switch self {
        case .year:  return .year
        case .month: return .month
        case .week:  return .month
        case .day:   return .day
        case .hour:  return .day
        }
    }

    var contextTitle: String {
        switch self {
        case .year:  return "今年時間感"
        case .month: return "本月時間感"
        case .week:  return "本週時間感"
        case .day:   return "今日時間感"
        case .hour:  return "今日倒數"
        }
    }

    var contextIcon: String {
        switch self {
        case .year:  return "calendar"
        case .month: return "calendar.badge.clock"
        case .week:  return "calendar.badge.clock"
        case .day:   return "sun.max"
        case .hour:  return "clock"
        }
    }

    func next() -> TimeFlowUnit {
        let all = Self.allCases
        guard let i = all.firstIndex(of: self) else { return .year }
        return all[(i + 1) % all.count]
    }
    func previous() -> TimeFlowUnit {
        let all = Self.allCases
        guard let i = all.firstIndex(of: self) else { return .year }
        return all[(i + all.count - 1) % all.count]
    }
}

// MARK: - LCD 液晶數字顯示

struct LCDNumberDisplay: View {
    let value: String
    var fontSize: CGFloat = 52

    private var ghostText: String {
        value.map { $0.isNumber ? "8" : $0 }.map(String.init).joined()
    }

    var body: some View {
        ZStack {
            Text(ghostText)
                .foregroundStyle(Color.white.opacity(0.055))
            Text(value)
                .foregroundStyle(Color.white)
                .contentTransition(.numericText(countsDown: true))
        }
        .font(.system(size: fontSize, weight: .ultraLight, design: .monospaced))
        .monospacedDigit()
        .shadow(color: LifeTheme.accent.opacity(0.22), radius: 10, x: 0, y: 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: value)
    }
}

// MARK: - 頂部整合區塊（與總覽 Hero 一致 + 時間感 Carousel）

struct LCDTimeFlowSection: View {
    let birthday: Date
    let lifeExpectancy: Int
    @Binding var heroUnit: TimeFlowHeroUnit

    @State private var autoTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var carouselUnit: TimeFlowUnit { heroUnit.timeFlowUnit }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TimelineView(.periodic(from: Date(), by: heroUnit.tickInterval)) { ctx in
                let metrics = LifeMetrics(birthday: birthday, lifeExpectancy: lifeExpectancy, now: ctx.date)

                HStack(alignment: .center, spacing: 20) {
                    LifeRemainingRing(percent: heroUnit.ringProgress(metrics: metrics))
                        .frame(width: 116, height: 116)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(heroUnit.headline)
                            .font(.subheadline)
                            .foregroundStyle(LifeTheme.textSecondary)
                            .animation(.easeInOut(duration: 0.2), value: heroUnit)

                        Button {
                            withAnimation(.snappy) { cycleHeroUnit() }
                            resetAutoTimer()
                        } label: {
                            Text(heroUnit.valueText(metrics: metrics))
                                .font(.system(size: heroUnit.valueFontSize, weight: .semibold, design: .monospaced))
                                .foregroundStyle(LifeTheme.accent)
                                .monospacedDigit()
                                .contentTransition(.numericText(countsDown: true))
                                .minimumScaleFactor(0.75)
                                .lineLimit(1)
                        }
                        .buttonStyle(.plain)

                        TimeContextCarousel(
                            unit: carouselUnit,
                            birthday: birthday,
                            lifeExpectancy: lifeExpectancy,
                            compact: true
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .cardStyle()
        .padding(.horizontal, 16)
        .onReceive(autoTimer) { _ in
            withAnimation(.snappy) { cycleHeroUnit() }
        }
    }

    private func cycleHeroUnit() {
        let all = TimeFlowHeroUnit.allCases
        guard let index = all.firstIndex(of: heroUnit) else { return }
        heroUnit = all[(index + 1) % all.count]
    }

    private func resetAutoTimer() {
        autoTimer.upstream.connect().cancel()
        autoTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    }
}

// MARK: - 時間感提示（純文字）

struct TimeContextCarousel: View {
    let unit: TimeFlowUnit
    let birthday: Date
    let lifeExpectancy: Int
    var compact: Bool = false

    var body: some View {
        TimelineView(.periodic(from: Date(), by: unit.tickInterval)) { ctx in
            let metrics = LifeMetrics(birthday: birthday, lifeExpectancy: lifeExpectancy, now: ctx.date)
            let line = buildLine(metrics: metrics, now: ctx.date)

            contextLine(line)
                .animation(.easeInOut(duration: 0.2), value: unit)
        }
    }

    struct ContextLine {
        let primary: String
        let secondary: String
    }

    private func contextLine(_ line: ContextLine) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(line.primary)
                .font(compact ? .caption : .subheadline)
                .foregroundStyle(LifeTheme.textSecondary)
                .lineLimit(compact ? 1 : 2)
                .minimumScaleFactor(0.85)
            Text(line.secondary)
                .font(.caption2)
                .foregroundStyle(LifeTheme.textTertiary)
                .lineLimit(compact ? 1 : 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func buildLine(metrics: LifeMetrics, now: Date) -> ContextLine {
        let cal = Calendar.current

        switch unit {
        case .year:
            let daysLeft = daysInYear(from: now, cal: cal)
            let pct = Int(metrics.progressOfCurrentYear * 100)
            return ContextLine(primary: "今年還剩 \(daysLeft) 天", secondary: "今年已過 \(pct)%")

        case .month:
            let dLeft = Int(metrics.daysRemainingThisMonth.rounded())
            let pct = Int(metrics.progressOfCurrentMonth * 100)
            return ContextLine(primary: "本月還剩 \(dLeft) 天", secondary: "本月已過 \(pct)%")

        case .week:
            let dLeft = max(0, Int(metrics.daysRemainingThisWeek))
            let pct = Int(metrics.progressOfCurrentWeek * 100)
            return ContextLine(primary: "本週還剩 \(dLeft) 天", secondary: "本週已過 \(pct)%")

        case .day:
            let hLeft = max(0, Int(metrics.hoursRemainingToday.rounded()))
            let pct = Int(metrics.progressOfCurrentDay * 100)
            return ContextLine(primary: "今天還剩 \(hLeft) 小時", secondary: "今天已過 \(pct)%")

        case .hour:
            let hPrecise = metrics.hoursRemainingToday
            let hInt = max(0, Int(hPrecise))
            let minInt = Int((hPrecise - Double(hInt)) * 60)
            let pct = Int(metrics.progressOfCurrentDay * 100)
            return ContextLine(
                primary: String(format: "今天還剩 %d 時 %02d 分", hInt, minInt),
                secondary: "今天已過 \(pct)%"
            )
        }
    }

    // MARK: Helpers

    private func daysInYear(from date: Date, cal: Calendar) -> Int {
        guard let end = cal.date(from: DateComponents(year: cal.component(.year, from: date) + 1, month: 1, day: 1)) else { return 0 }
        return max(0, cal.dateComponents([.day], from: cal.startOfDay(for: date), to: end).day ?? 0)
    }
}

// MARK: - 時間情境推薦區塊（今天可做 + 長期目標下一步）

struct TimeRecommendationSection: View {
    let heroUnit: TimeFlowHeroUnit
    let birthday: Date
    let lifeExpectancy: Int
    let goals: [LifeGoal]
    let tasks: [LifeTask]
    let familyMembers: [FamilyMember]
    let batch: Int
    let onAction: (TimeRecommendationAction) -> Void
    let onRefresh: () -> Void

    @State private var refreshRotation: Double = 0

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { timeline in
            let metrics = LifeMetrics(birthday: birthday, lifeExpectancy: lifeExpectancy, now: timeline.date)
            let recommendations = TimeRecommendationEngine.recommendations(
                context: TimeRecommendationContext(
                    now: timeline.date,
                    metrics: metrics,
                    scope: heroUnit.recommendationScope,
                    goals: goals,
                    tasks: tasks,
                    familyMembers: familyMembers,
                    batch: batch
                )
            )

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 0) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13))
                            .foregroundStyle(LifeTheme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(sectionTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(LifeTheme.textPrimary)
                            Text(sectionSubtitle)
                                .font(.caption2)
                                .foregroundStyle(LifeTheme.textTertiary)
                        }
                    }
                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.65)) {
                            refreshRotation += 180
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onRefresh()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption.weight(.medium))
                                .rotationEffect(.degrees(refreshRotation))
                            Text("換一批")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(LifeTheme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(LifeTheme.accentSoft))
                    }
                    .buttonStyle(.plain)
                }

                if recommendations.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 10) {
                        ForEach(Array(recommendations.enumerated()), id: \.element.id) { index, recommendation in
                            recommendationCard(recommendation, isPrimary: index == 0)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.spring(response: 0.38, dampingFraction: 0.78), value: batch)
                    .animation(.spring(response: 0.38, dampingFraction: 0.78), value: heroUnit)
                }
            }
        }
    }

    private var sectionTitle: String {
        switch heroUnit {
        case .yearDays: return "今年可以先做什麼"
        case .monthDays: return "本月可以推進什麼"
        case .todayTime: return "現在最適合"
        }
    }

    private var sectionSubtitle: String {
        switch heroUnit {
        case .yearDays: return "年度視角，只拆成今天可開始的小步"
        case .monthDays: return "月度視角，推薦本月能安排的第一步"
        case .todayTime: return "依當前時段，只推薦今天可做的小行動"
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 30))
                .foregroundStyle(LifeTheme.accent.opacity(0.75))
            Text("現在先不用新增行動")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(LifeTheme.textPrimary)
            Text("深夜或沒有合適資料時，時間頁會優先建議休息，而不是硬塞任務。")
                .font(.caption)
                .foregroundStyle(LifeTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.045))
        )
    }

    private func recommendationCard(_ recommendation: TimeRecommendation, isPrimary: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LifeTheme.accentSoft)
                        .frame(width: isPrimary ? 38 : 32, height: isPrimary ? 38 : 32)
                    Image(systemName: recommendation.category.iconName)
                        .font(.system(size: isPrimary ? 16 : 13))
                        .foregroundStyle(LifeTheme.accent)
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(recommendation.sourceLabel)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(LifeTheme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(LifeTheme.accentSoft))

                        if let minutes = recommendation.estimatedMinutes {
                            Text("\(minutes) 分鐘")
                                .font(.caption2)
                                .foregroundStyle(LifeTheme.textTertiary)
                        }
                    }

                    Text(recommendation.title)
                        .font(isPrimary ? .headline : .subheadline.weight(.semibold))
                        .foregroundStyle(LifeTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(recommendation.subtitle)
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(recommendation.reason)
                .font(.caption)
                .foregroundStyle(LifeTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(recommendation.sopSteps.prefix(3).enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1)")
                            .font(.caption2.monospacedDigit().weight(.semibold))
                            .foregroundStyle(LifeTheme.accent)
                            .frame(width: 16, height: 16)
                            .background(Circle().fill(LifeTheme.accentSoft))
                        Text(step)
                            .font(.caption)
                            .foregroundStyle(LifeTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            actionButton(for: recommendation)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(isPrimary ? 0.06 : 0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isPrimary ? LifeTheme.accent.opacity(0.22) : Color.white.opacity(0.06), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private func actionButton(for recommendation: TimeRecommendation) -> some View {
        switch recommendation.action {
        case .addTask:
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                    onAction(recommendation.action)
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                Label("加入今日", systemImage: "plus.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LifeTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(LifeTheme.accentSoft))
            }
            .buttonStyle(.plain)

        case .openGoal:
            Button {
                onAction(recommendation.action)
            } label: {
                Label("打開目標", systemImage: "arrow.up.right.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LifeTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(LifeTheme.accentSoft))
            }
            .buttonStyle(.plain)

        case .none:
            EmptyView()
        }
    }
}
