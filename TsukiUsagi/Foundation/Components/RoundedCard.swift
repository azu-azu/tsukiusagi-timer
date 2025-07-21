import SwiftUI
import Foundation

/// 統一カードスタイルコンポーネント
/// Asset Catalog からカラーを参照し、Light/Dark モードに対応
struct RoundedCard<Content: View>: View {
    // MARK: - Properties

    let content: Content
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    let backgroundColor: Color

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.sizeCategory) private var sizeCategory

    // MARK: - Initializers

    /// 標準的なカード
    /// - Parameters:
    ///   - cornerRadius: 角丸の半径（デフォルト: DesignTokens.CornerRadius.medium）
    ///   - padding: 内部パディング（デフォルト: DesignTokens.Padding.card）
    ///   - backgroundColor: 背景色（デフォルト: Asset Catalog から自動取得）
    ///   - content: カードの内容
    init(
        cornerRadius: CGFloat = DesignTokens.CornerRadius.medium,
        padding: EdgeInsets = EdgeInsets(
            top: DesignTokens.Padding.card,
            leading: DesignTokens.Padding.card,
            bottom: DesignTokens.Padding.card,
            trailing: DesignTokens.Padding.card
        ),
        backgroundColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.backgroundColor = backgroundColor ?? DesignTokens.Colors.cosmosCardBG
    }

    /// コンパクト/大きなカード（パディング切り替え）
    /// - Parameters:
    ///   - isCompact: コンパクトかどうか
    ///   - isLarge: 大きいかどうか
    ///   - cornerRadius: 角丸の半径
    ///   - backgroundColor: 背景色
    ///   - content: カードの内容
    init(
        isCompact: Bool = false,
        isLarge: Bool = false,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.medium,
        backgroundColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.cornerRadius = cornerRadius
        if isLarge {
            padding = EdgeInsets(
                top: DesignTokens.Padding.large,
                leading: DesignTokens.Padding.large,
                bottom: DesignTokens.Padding.large,
                trailing: DesignTokens.Padding.large
            )
        } else if isCompact {
            padding = EdgeInsets(
                top: DesignTokens.Padding.small,
                leading: DesignTokens.Padding.medium,
                bottom: DesignTokens.Padding.small,
                trailing: DesignTokens.Padding.medium
            )
        } else {
            padding = EdgeInsets(
                top: DesignTokens.Padding.card,
                leading: DesignTokens.Padding.card,
                bottom: DesignTokens.Padding.card,
                trailing: DesignTokens.Padding.card
            )
        }
        self.backgroundColor = backgroundColor ?? DesignTokens.Colors.cosmosCardBG
    }

    // MARK: - Body

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
            )
    }
}

// MARK: - Convenience Modifiers

extension View {
    /// 標準的なカードスタイルを適用
    func roundedCard(
        cornerRadius: CGFloat = DesignTokens.CornerRadius.medium,
        padding: EdgeInsets? = nil,
        backgroundColor: Color? = nil
    ) -> some View {
        RoundedCard(
            cornerRadius: cornerRadius,
            padding: padding ?? EdgeInsets(
                top: DesignTokens.Padding.card,
                leading: DesignTokens.Padding.card,
                bottom: DesignTokens.Padding.card,
                trailing: DesignTokens.Padding.card
            ),
            backgroundColor: backgroundColor
        ) {
            self
        }
    }

    /// コンパクトなカードスタイルを適用
    func compactCard(
        cornerRadius: CGFloat = DesignTokens.CornerRadius.medium,
        backgroundColor: Color? = nil
    ) -> some View {
        RoundedCard(isCompact: true, cornerRadius: cornerRadius, backgroundColor: backgroundColor) {
            self
        }
    }

    /// 大きなカードスタイルを適用
    func largeCard(
        cornerRadius: CGFloat = DesignTokens.CornerRadius.large,
        backgroundColor: Color? = nil
    ) -> some View {
        RoundedCard(isLarge: true, cornerRadius: cornerRadius, backgroundColor: backgroundColor) {
            self
        }
    }
}

// MARK: - Preview

#Preview("RoundedCard") {
    VStack(spacing: 20) {
        // 標準カード
        RoundedCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Standard Card")
                    .font(DesignTokens.Fonts.labelBold)
                Text("This is a standard card with default padding and styling.")
                    .font(DesignTokens.Fonts.label)
            }
        }

        // コンパクトカード
        RoundedCard(isCompact: true, cornerRadius: DesignTokens.CornerRadius.small) {
            HStack {
                Text("Compact Card")
                    .font(DesignTokens.Fonts.sectionTitle)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(DesignTokens.Colors.moonTextMuted)
            }
        }

        // 大きなカード
        RoundedCard(isLarge: true, cornerRadius: DesignTokens.CornerRadius.large) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Large Card")
                    .font(DesignTokens.Fonts.title)
                Text("This is a large card with more padding and a larger corner radius.")
                    .font(DesignTokens.Fonts.label)
                Button("Action") {
                    // Action
                }
                .buttonStyle(.borderedProminent)
            }
        }

        // カスタム背景色
        RoundedCard(
            cornerRadius: DesignTokens.CornerRadius.medium,
            backgroundColor: DesignTokens.Colors.moonErrorBackground.opacity(0.3)
        ) {
            Text("Custom Background")
                .font(DesignTokens.Fonts.label)
        }
    }
    .padding()
    .background(DesignTokens.Colors.cosmosBackground)
    .previewColorSchemes()
}
