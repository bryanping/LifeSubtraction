import SwiftUI

enum GridMode: String, CaseIterable {
    case weeks = "週"
    case years = "年"
}

struct WeekGridView: View {
    @EnvironmentObject var store: LifeStore
    @State private var mode: GridMode = .years

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Mode picker
                    Picker("顯示模式", selection: $mode) {
                        ForEach(GridMode.allCases, id: \.self) { m in
                            Text("生命\(m.rawValue)").tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // 剩餘格點視覺化（保留你的順序）  // modified
                    remainingGrid
                        .padding(.horizontal)

                    pastSummaryCard
                        .padding(.horizontal)

                    statsLine
                        .padding(.horizontal)

                    legendRow
                        .padding(.horizontal)
                }
                .padding(.top, 12)
            }
            .scrollContentBackground(.hidden)                              // // modified
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("生命\(mode.rawValue)格")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)               // // modified
            .animation(.easeInOut(duration: 0.25), value: mode)
        }
    }

    // MARK: - 已過摘要卡  // modified

    var pastSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(LifeTheme.accent)
                Text(mode == .years ? "已度過的年" : "已度過的週")
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(LifeTheme.textSecondary)              // // modified
                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(mode == .years ? "\(store.ageYears)" : store.weeksLived.formatted())
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .foregroundStyle(LifeTheme.accent)
                Text(mode == .years ? "個年頭" : "個星期")
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textSecondary)              // // modified
                Spacer()
                Text("已過 \(percentString)")
                    .font(.caption).fontWeight(.medium)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(LifeTheme.accentSoft, in: Capsule())
                    .foregroundStyle(LifeTheme.accent)
            }

            ProgressBar(value: store.percentUsed)

            Rectangle()
                .fill(Color.white.opacity(0.08))                            // // modified — 自繪 divider
                .frame(height: 0.5)

            // 當前年/週進度條  // modified
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(LifeTheme.warm)
                    Text(currentLabel)
                        .font(.footnote)
                        .foregroundStyle(LifeTheme.textSecondary)          // // modified
                    Spacer()
                    Text("\(Int(currentProgress * 100))%")
                        .font(.footnote).fontWeight(.medium)
                        .foregroundStyle(LifeTheme.warm)
                }
                ProgressBar(value: currentProgress, color: LifeTheme.warm, useGradient: false) // // modified
            }
        }
        .cardStyle()
    }

    private var percentString: String {
        let pct = Int((store.percentUsed * 100).rounded())
        return "\(pct)%"
    }

    private var currentLabel: String {
        if mode == .years {
            return "目前在第 \(store.ageYears + 1) 年（\(store.ageYears) 歲）"
        } else {
            return "目前在第 \(store.weeksLived + 1) 週"
        }
    }

    private var currentProgress: Double {
        mode == .years ? store.metrics.progressOfCurrentYear : store.metrics.progressOfCurrentWeek
    }

    // MARK: - 統計列  // modified

    var statsLine: some View {
        HStack(spacing: 10) {
            if mode == .years {
                statPill(value: "\(store.ageYears)", label: "歲", icon: "person.fill")
                statPill(value: "\(max(0, store.lifeExpectancy - store.ageYears))", label: "年剩餘", icon: "calendar", accent: true)
            } else {
                statPill(value: store.weeksLived.formatted(), label: "週已過", icon: "checkmark.circle")
                statPill(value: store.weeksRemaining.formatted(), label: "週剩餘", icon: "infinity", accent: true)
            }
        }
    }

    func statPill(value: String, label: String, icon: String, accent: Bool = false) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(accent ? LifeTheme.accent : LifeTheme.textSecondary) // // modified
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(.subheadline, design: .rounded)).fontWeight(.semibold)
                    .foregroundStyle(accent ? LifeTheme.accent : LifeTheme.textPrimary) // // modified
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(LifeTheme.textSecondary)              // // modified
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LifeTheme.glassFill)                                  // // modified
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(LifeTheme.glassBorder, lineWidth: 0.5)              // // modified
        )
    }

    var legendRow: some View {
        HStack(spacing: 18) {
            LegendItem(color: LifeTheme.warm, label: "現在")
            LegendItem(color: LifeTheme.accent, label: "剩餘")
            Spacer()
            Text("已過已折算為文字")
                .font(.caption2)
                .foregroundStyle(LifeTheme.textTertiary)                    // // modified
        }
    }

    // MARK: - 剩餘格網

    @ViewBuilder
    var remainingGrid: some View {
        if mode == .years {
            FutureYearGrid(
                lifeExpectancy: store.lifeExpectancy,
                ageYears: store.ageYears,
                progressInYear: store.metrics.progressOfCurrentYear
            )
            .cardStyle(padding: 16)
        } else {
            FutureWeekGrid(
                lifeExpectancy: store.lifeExpectancy,
                weeksLived: store.weeksLived,
                totalWeeks: store.totalWeeks,
                progressInWeek: store.metrics.progressOfCurrentWeek
            )
            .cardStyle(padding: 14)
        }
    }
}

// MARK: - Future Year Grid

struct FutureYearGrid: View {
    let lifeExpectancy: Int
    let ageYears: Int
    let progressInYear: Double

    let cellSize: CGFloat = 30
    let spacing: CGFloat = 7
    let cornerRadius: CGFloat = 6

    private var futureCount: Int {
        max(0, lifeExpectancy - ageYears)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("剩餘 \(futureCount) 年")
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(LifeTheme.textPrimary)                // // modified

                Spacer()

                Text("\(ageYears + 1) → \(lifeExpectancy)")
                    .font(.caption2)
                    .foregroundStyle(LifeTheme.textTertiary)               // // modified
            }

            GeometryReader { geo in
                let availableWidth = geo.size.width
                let cols = max(1, Int((availableWidth + spacing) / (cellSize + spacing)))
                let rows = max(1, Int(ceil(Double(futureCount) / Double(cols))))
                let gridHeight = CGFloat(rows) * (cellSize + spacing) - spacing

                Canvas { ctx, _ in
                    for i in 0..<futureCount {
                        let col = i % cols
                        let row = i / cols
                        let x = CGFloat(col) * (cellSize + spacing)
                        let y = CGFloat(row) * (cellSize + spacing)
                        let rect = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                        let path = Path(roundedRect: rect, cornerRadius: cornerRadius)

                        if i == 0 {
                            // 當前年：底色 + 進度填充（暖色，僅此處）  // modified
                            ctx.fill(path, with: .color(LifeTheme.warm.opacity(0.20)))
                            let progressRect = CGRect(
                                x: x, y: y,
                                width: cellSize * CGFloat(progressInYear),
                                height: cellSize
                            )
                            let progressPath = Path(roundedRect: progressRect, cornerRadius: cornerRadius)
                            ctx.fill(progressPath, with: .color(LifeTheme.warm))
                            ctx.stroke(path, with: .color(LifeTheme.warm), lineWidth: 1.0)
                        } else {
                            ctx.fill(path, with: .color(LifeTheme.accentSoft))
                            ctx.stroke(path, with: .color(LifeTheme.accentMuted), lineWidth: 0.5)
                        }

                        let label = "\(ageYears + i + 1)"
                        let textColor: Color = i == 0
                            ? Color.white
                            : LifeTheme.accent.opacity(0.85)

                        ctx.draw(
                            Text(label)
                                .font(.system(size: 10, weight: i == 0 ? .bold : .regular))
                                .foregroundColor(textColor),
                            at: CGPoint(x: x + cellSize / 2, y: y + cellSize / 2),
                            anchor: .center
                        )
                    }
                }
                .frame(width: availableWidth, height: gridHeight)
            }
            .frame(height: calculatedHeight)
        }
    }

    private var calculatedHeight: CGFloat {
        // 保守估算高度  // modified
        let estimatedCols = 8
        let rows = max(1, Int(ceil(Double(futureCount) / Double(estimatedCols))))
        return CGFloat(rows) * (cellSize + spacing) - spacing
    }
}

// MARK: - Future Week Grid（精簡版）

struct FutureWeekGrid: View {
    let lifeExpectancy: Int
    let weeksLived: Int
    let totalWeeks: Int
    let progressInWeek: Double

    let dotSize: CGFloat = 8
    let spacing: CGFloat = 5

    private var futureCount: Int { max(0, totalWeeks - weeksLived) }
    private var remainingYears: Int { futureCount / 52 }
    private var remainingWeeks: Int { futureCount % 52 }
    private var previewWeeks: Int { min(52, futureCount) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("剩餘週數")
                        .font(.subheadline)
                        .foregroundStyle(LifeTheme.textSecondary)          // // modified
                    Text(futureCount.formatted())
                        .font(.system(size: 44, weight: .semibold, design: .rounded))
                        .foregroundStyle(LifeTheme.accent)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("約剩")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textSecondary)          // // modified
                    Text("\(remainingYears) 年 \(remainingWeeks) 週")
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(LifeTheme.textPrimary)            // // modified
                }
            }

            ProgressBar(value: Double(weeksLived) / Double(max(1, totalWeeks)))

            Rectangle()
                .fill(Color.white.opacity(0.08))                            // // modified
                .frame(height: 0.5)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("接下來一年")
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(LifeTheme.textPrimary)            // // modified
                    Spacer()
                    Text("最多顯示 52 週")
                        .font(.caption2)
                        .foregroundStyle(LifeTheme.textTertiary)           // // modified
                }

                GeometryReader { geo in
                    let availableWidth = geo.size.width
                    let cols = max(1, Int((availableWidth + spacing) / (dotSize + spacing)))
                    let rows = max(1, Int(ceil(Double(previewWeeks) / Double(cols))))
                    let gridHeight = CGFloat(rows) * (dotSize + spacing) - spacing

                    Canvas { ctx, _ in
                        for i in 0..<previewWeeks {
                            let col = i % cols
                            let row = i / cols
                            let x = CGFloat(col) * (dotSize + spacing)
                            let y = CGFloat(row) * (dotSize + spacing)
                            let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                            let path = Path(ellipseIn: rect)

                            if i == 0 {
                                ctx.fill(path, with: .color(LifeTheme.warm))
                            } else {
                                ctx.fill(path, with: .color(LifeTheme.accentSoft))
                            }
                        }
                    }
                    .frame(width: availableWidth, height: gridHeight)
                }
                .frame(height: previewGridHeight)
            }
        }
    }

    private var previewGridHeight: CGFloat {
        let estimatedCols = 28
        let rows = max(1, Int(ceil(Double(previewWeeks) / Double(estimatedCols))))
        return CGFloat(rows) * (dotSize + spacing) - spacing
    }
}

// MARK: - LegendItem  // modified
// 注意：ProgressBar 已搬到 LifeTheme.swift，此處不再定義避免重複。

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label)
                .font(.caption)
                .foregroundStyle(LifeTheme.textSecondary)                  // // modified
        }
    }
}
