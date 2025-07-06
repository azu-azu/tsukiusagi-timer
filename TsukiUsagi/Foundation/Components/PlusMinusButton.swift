import SwiftUI

/// プラス/マイナスボタンコンポーネント
/// 時間設定で使用する統一されたボタンスタイル
struct PlusMinusButton: View {

    // MARK: - Properties
    let systemName: String
    let action: () -> Void
    let size: CGFloat
    let padding: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    let isEnabled: Bool

    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.sizeCategory) private var sizeCategory

    // MARK: - Initializers

    /// 標準的なプラス/マイナスボタン
    /// - Parameters:
    ///   - systemName: SF Symbol名
    ///   - action: タップ時のアクション
    ///   - size: アイコンサイズ
    ///   - padding: パディング
    ///   - backgroundColor: 背景色
    ///   - foregroundColor: 前景色
    ///   - isEnabled: 有効/無効
    init(
        systemName: String,
        action: @escaping () -> Void,
        size: CGFloat = DesignTokens.FontSize.caption,
        padding: CGFloat = DesignTokens.Padding.small,
        backgroundColor: Color? = nil,
        foregroundColor: Color? = nil,
        isEnabled: Bool = true
    ) {
        self.systemName = systemName
        self.action = action
        self.size = size
        self.padding = padding
        self.backgroundColor = backgroundColor ?? Color.white.opacity(0.1)
        self.foregroundColor = foregroundColor ?? .white
        self.isEnabled = isEnabled
    }

    /// マイナスボタン
    /// - Parameters:
    ///   - action: タップ時のアクション
    ///   - isEnabled: 有効/無効
    init(
        minus action: @escaping () -> Void,
        isEnabled: Bool = true
    ) {
        self.systemName = "minus"
        self.action = action
        self.size = DesignTokens.FontSize.caption
        self.padding = DesignTokens.Padding.small
        self.backgroundColor = Color.white.opacity(0.1)
        self.foregroundColor = .white
        self.isEnabled = isEnabled
    }

    /// プラスボタン
    /// - Parameters:
    ///   - action: タップ時のアクション
    ///   - isEnabled: 有効/無効
    init(
        plus action: @escaping () -> Void,
        isEnabled: Bool = true
    ) {
        self.systemName = "plus"
        self.action = action
        self.size = DesignTokens.FontSize.caption
        self.padding = DesignTokens.Padding.small
        self.backgroundColor = Color.white.opacity(0.1)
        self.foregroundColor = .white
        self.isEnabled = isEnabled
    }

    // MARK: - Body
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundColor(isEnabled ? foregroundColor : foregroundColor.opacity(0.5))
                .padding(padding)
                .background(
                    Circle()
                        .fill(isEnabled ? backgroundColor : backgroundColor.opacity(0.5))
                )
        }
        .disabled(!isEnabled)
        .accessibilityLabel(systemName == "plus" ? "Increase" : "Decrease")
        .accessibilityHint(systemName == "plus" ? "Tap to increase value" : "Tap to decrease value")
    }
}

/// プラス/マイナスボタンのペア
struct PlusMinusButtonPair: View {

    // MARK: - Properties
    let onMinus: () -> Void
    let onPlus: () -> Void
    let minusEnabled: Bool
    let plusEnabled: Bool
    let spacing: CGFloat

    // MARK: - Initializers

    /// 標準的なプラス/マイナスボタンペア
    /// - Parameters:
    ///   - onMinus: マイナスボタンのアクション
    ///   - onPlus: プラスボタンのアクション
    ///   - minusEnabled: マイナスボタンの有効/無効
    ///   - plusEnabled: プラスボタンの有効/無効
    ///   - spacing: ボタン間のスペース
    init(
        onMinus: @escaping () -> Void,
        onPlus: @escaping () -> Void,
        minusEnabled: Bool = true,
        plusEnabled: Bool = true,
        spacing: CGFloat = DesignTokens.Spacing.small
    ) {
        self.onMinus = onMinus
        self.onPlus = onPlus
        self.minusEnabled = minusEnabled
        self.plusEnabled = plusEnabled
        self.spacing = spacing
    }

    // MARK: - Body
    var body: some View {
        HStack(spacing: spacing) {
            PlusMinusButton(minus: onMinus, isEnabled: minusEnabled)
            PlusMinusButton(plus: onPlus, isEnabled: plusEnabled)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Adjust value")
        .accessibilityHint("Use minus button to decrease, plus button to increase")
    }
}

// MARK: - Convenience Modifiers
extension View {
    /// プラス/マイナスボタンペアを適用
    func plusMinusButtons(
        onMinus: @escaping () -> Void,
        onPlus: @escaping () -> Void,
        minusEnabled: Bool = true,
        plusEnabled: Bool = true,
        spacing: CGFloat = DesignTokens.Spacing.small
    ) -> some View {
        HStack(spacing: spacing) {
            PlusMinusButton(minus: onMinus, isEnabled: minusEnabled)
            PlusMinusButton(plus: onPlus, isEnabled: plusEnabled)
        }
    }
}

// MARK: - Preview
#Preview("PlusMinusButton") {
    VStack(spacing: 30) {
        // 個別ボタン
        HStack(spacing: 20) {
            PlusMinusButton(minus: {})
            PlusMinusButton(plus: {})
        }

        // 無効化されたボタン
        HStack(spacing: 20) {
            PlusMinusButton(minus: {}, isEnabled: false)
            PlusMinusButton(plus: {}, isEnabled: false)
        }

        // ボタンペア
        PlusMinusButtonPair(
            onMinus: {},
            onPlus: {}
        )

        // カスタムスタイル
        HStack(spacing: 20) {
            PlusMinusButton(
                systemName: "minus",
                action: {},
                size: 16,
                padding: 12,
                backgroundColor: DesignTokens.Colors.moonAccentBlue.opacity(0.3),
                foregroundColor: DesignTokens.Colors.moonAccentBlue
            )
            PlusMinusButton(
                systemName: "plus",
                action: {},
                size: 16,
                padding: 12,
                backgroundColor: DesignTokens.Colors.moonAccentBlue.opacity(0.3),
                foregroundColor: DesignTokens.Colors.moonAccentBlue
            )
        }
    }
    .padding()
    .background(DesignTokens.Colors.moonBackground)
    .previewColorSchemes()
}