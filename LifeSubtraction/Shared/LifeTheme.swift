import SwiftUI

// MARK: - LifeTheme  (// modified — full dark design system)
// 暗色 minimalism + Apple design language + 沉靜時間感。
// 所有顏色都是純 Color（不依賴 Asset Catalog、也不用 SwiftUI 適應色），
// 全 App / Widget / Watch 任一 target 表現一致。

public enum LifeTheme {

    // MARK: - 背景（藍黑、深邃）  // modified
    public static let background      = Color(red: 0.04, green: 0.06, blue: 0.10)
    public static let backgroundDeep  = Color(red: 0.02, green: 0.03, blue: 0.07)
    public static let surfaceElevated = Color(red: 0.07, green: 0.10, blue: 0.16)

    // MARK: - 文字 token（白色 + 透明度）  // modified
    // 規則：禁止使用 .secondary / .tertiary 縮寫，全部走 Color。
    public static let textPrimary   = Color.white
    public static let textSecondary = Color.white.opacity(0.70)
    public static let textTertiary  = Color.white.opacity(0.40)
    public static let textQuaternary = Color.white.opacity(0.20)

    // MARK: - 強調色：teal → blue 漸層  // modified
    public static let accent     = Color(red: 0.20, green: 0.85, blue: 0.80)   // 主 teal
    public static let accentEnd  = Color(red: 0.30, green: 0.55, blue: 0.95)   // 漸層終點 blue
    public static let accentSoft  = Color(red: 0.20, green: 0.85, blue: 0.80).opacity(0.18)
    public static let accentMuted = Color(red: 0.20, green: 0.85, blue: 0.80).opacity(0.32)

    // MARK: - 暖色（僅用於：今天 / 當前進度 / 急迫）  // modified
    public static let warm     = Color(red: 1.00, green: 0.62, blue: 0.36)
    public static let warmSoft = Color(red: 1.00, green: 0.62, blue: 0.36).opacity(0.18)

    // MARK: - 漸層

    /// 主 hero 漸層：teal → blue（取代之前的 teal → purple）  // modified
    public static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// App 全域背景：深藍黑 + 微微光暈感的縱向漸層  // modified
    public static var subtleBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.08, blue: 0.13),
                Color(red: 0.02, green: 0.03, blue: 0.07)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// 進度條漸層（capsule 用）  // modified
    public static var progressGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentEnd],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// 卡片底色：白色低透明 + 微噪點感（純色模擬）  // modified
    public static let glassFill   = Color.white.opacity(0.05)
    public static let glassBorder = Color.white.opacity(0.08)
}

// MARK: - GlassCardStyle  // modified
// 半透明 + 細邊框 + 圓角，深色背景下自然有玻璃感。

public struct GlassCardStyle: ViewModifier {
    var padding: CGFloat = 18
    var cornerRadius: CGFloat = 20

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(LifeTheme.glassFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
            )
    }
}

public extension View {
    /// 玻璃風卡片（保留舊 API 名稱，避免大量改寫呼叫端）  // modified
    func cardStyle(padding: CGFloat = 18) -> some View {
        modifier(GlassCardStyle(padding: padding))
    }

    /// 玻璃風卡片，明確命名版  // modified
    func glassCard(padding: CGFloat = 18, cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCardStyle(padding: padding, cornerRadius: cornerRadius))
    }
}

// MARK: - ProgressBar  // modified
// Capsule + teal→blue 漸層 + 平滑動畫。全 App 統一使用。

public struct ProgressBar: View {
    public var value: Double               // 0...1
    public var color: Color = LifeTheme.accent
    public var height: CGFloat = 10
    public var useGradient: Bool = true

    public init(value: Double,
                color: Color = LifeTheme.accent,
                height: CGFloat = 10,
                useGradient: Bool = true) {
        self.value = value
        self.color = color
        self.height = height
        self.useGradient = useGradient
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.10))                        // // modified
                Capsule()
                    .fill(
                        useGradient
                        ? AnyShapeStyle(LifeTheme.progressGradient)
                        : AnyShapeStyle(color)
                    )
                    .frame(width: max(2, geo.size.width * CGFloat(min(1, max(0, value)))))
                    .animation(.easeInOut(duration: 0.6), value: value)     // // modified
            }
        }
        .frame(height: height)
    }
}

// MARK: - PrimaryButton / SecondaryButton  // modified

/// 漸層 capsule 主按鈕。
public struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    public init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title).fontWeight(.semibold)
            }
            .font(.headline)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule().fill(LifeTheme.heroGradient)
            )
            .overlay(
                Capsule().stroke(Color.white.opacity(0.10), lineWidth: 0.5)
            )
            .shadow(color: LifeTheme.accent.opacity(0.25), radius: 14, y: 6) // 微 glow
        }
        .buttonStyle(.plain)
    }
}

/// 半透明 capsule 副按鈕。
public struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    public init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(.subheadline).fontWeight(.medium)
            .foregroundStyle(Color.white.opacity(0.85))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Capsule().fill(Color.white.opacity(0.06))
            )
            .overlay(
                Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
