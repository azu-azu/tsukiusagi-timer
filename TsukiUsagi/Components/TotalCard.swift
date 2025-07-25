import SwiftUI
import Foundation

/// 合計表示用カードコンポーネント
/// History/Settings で使用する統一された合計表示スタイル
struct TotalCard: View {
    // MARK: - Properties

    let text: String
    let cornerRadius: CGFloat
    let backgroundColor: Color
    let textColor: Color
    let showGlitter: Bool
    let glitterSize: CGFloat
    let glitterResource: String

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.sizeCategory) private var sizeCategory

    // MARK: - Initializers

    /// 標準的な合計カード
    /// - Parameters:
    ///   - text: 表示テキスト
    ///   - cornerRadius: 角丸の半径
    ///   - backgroundColor: 背景色
    ///   - textColor: テキスト色
    ///   - showGlitter: キラキラエフェクトの表示
    ///   - glitterSize: キラキラエフェクトのサイズ
    ///   - glitterResource: キラキラエフェクトのリソース名
    init(
        text: String,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.medium,
        backgroundColor: Color? = nil,
        textColor: Color? = nil,
        showGlitter: Bool = true,
        glitterSize: CGFloat = 24,
        glitterResource: String = "gold"
    ) {
        self.text = text
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor ?? DesignTokens.CosmosColors.cardBackground.opacity(0.2)
        self.textColor = textColor ?? DesignTokens.MoonColors.textPrimary
        self.showGlitter = showGlitter
        self.glitterSize = glitterSize
        self.glitterResource = glitterResource
    }

    /// シンプルな合計カード（キラキラエフェクトなし）
    /// - Parameters:
    ///   - text: 表示テキスト
    ///   - cornerRadius: 角丸の半径
    ///   - backgroundColor: 背景色
    ///   - textColor: テキスト色
    init(
        simple text: String,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.medium,
        backgroundColor: Color? = nil,
        textColor: Color? = nil
    ) {
        self.text = text
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor ?? DesignTokens.CosmosColors.cardBackground.opacity(0.15)
        self.textColor = textColor ?? DesignTokens.MoonColors.textPrimary
        showGlitter = false
        glitterSize = 0
        glitterResource = ""
    }

    // MARK: - Body

    var body: some View {
        Group {
            if showGlitter {
                Text(text)
                    .glitter(size: glitterSize)
            } else {
                Text(text)
            }
        }
        .font(DesignTokens.Fonts.numericLabel)
        .foregroundColor(textColor)
        .padding(DesignTokens.Padding.card)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(backgroundColor)
        )
        .padding(.horizontal, DesignTokens.Padding.medium)
    }
}

// MARK: - Convenience Modifiers

extension View {
    /// 合計カードスタイルを適用
    func totalCard(
        text: String,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.medium,
        backgroundColor: Color? = nil,
        textColor: Color? = nil,
        showGlitter: Bool = true,
        glitterSize: CGFloat = 24,
        glitterResource: String = "gold"
    ) -> some View {
        TotalCard(
            text: text,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            textColor: textColor,
            showGlitter: showGlitter,
            glitterSize: glitterSize,
            glitterResource: glitterResource
        )
    }

    /// シンプルな合計カードスタイルを適用
    func simpleTotalCard(
        text: String,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.medium,
        backgroundColor: Color? = nil,
        textColor: Color? = nil
    ) -> some View {
        TotalCard(
            simple: text,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            textColor: textColor
        )
    }
}

// MARK: - Conditional Glitter Extension

// 旧glitter/conditionalGlitter拡張は不要になったため削除

// MARK: - Preview

#Preview("TotalCard") {
    VStack(spacing: 20) {
        // 標準合計カード
        TotalCard(text: "Total: 2h 30m")

        // シンプル合計カード
        TotalCard(simple: "Total: 1h 45m")

        // カスタムスタイル
        TotalCard(
            text: "Custom Style",
            cornerRadius: DesignTokens.CornerRadius.large,
            backgroundColor: DesignTokens.MoonColors.errorBackground.opacity(0.3),
            textColor: .white,
            showGlitter: false
        )

        // 大きなキラキラ
        TotalCard(
            text: "Large Glitter",
            glitterSize: 32,
            glitterResource: "gold"
        )
    }
    .padding()
    .background(DesignTokens.CosmosColors.background)
    .previewColorSchemes()
}
