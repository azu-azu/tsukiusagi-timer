import SwiftUI

/// Dynamic Type 対応のフォント拡張メソッド
/// サイズ調整ロジックを一元化し、アクセシビリティ対応を保証
extension View {

    /// スケーラブルフォント（Dynamic Type対応）
    /// - Parameters:
    ///   - style: フォントスタイル
    ///   - weight: フォントの太さ（デフォルト: .regular）
    ///   - design: フォントデザイン（デフォルト: .rounded）
    ///   - maxSize: 最大サイズ（アクセシビリティ対応）
    func scaledFont(
        style: Font.TextStyle,
        weight: Font.Weight = .regular,
        design: Font.Design = .rounded,
        maxSize: DynamicTypeSize = .accessibility5
    ) -> some View {
        self
            .font(.system(style, design: design, weight: weight))
            .dynamicTypeSize(...maxSize)
    }

    /// スケーラブルフォント（サイズ指定）
    /// - Parameters:
    ///   - size: フォントサイズ
    ///   - weight: フォントの太さ（デフォルト: .regular）
    ///   - design: フォントデザイン（デフォルト: .rounded）
    ///   - maxSize: 最大サイズ（アクセシビリティ対応）
    func scaledFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .rounded,
        maxSize: DynamicTypeSize = .accessibility5
    ) -> some View {
        self
            .font(.system(size: size, weight: weight, design: design))
            .dynamicTypeSize(...maxSize)
    }

    // MARK: - プリセットスタイル

    /// 見出し用フォント
    func headlineFont() -> some View {
        scaledFont(style: .headline, weight: .semibold)
    }

    /// サブヘッドライン用フォント
    func subheadlineFont() -> some View {
        scaledFont(style: .subheadline, weight: .semibold)
    }

    /// ボディ用フォント
    func bodyFont() -> some View {
        scaledFont(style: .body, weight: .regular)
    }

    /// キャプション用フォント
    func captionFont() -> some View {
        scaledFont(style: .caption, weight: .regular)
    }

    /// タイトル用フォント
    func titleFont() -> some View {
        scaledFont(style: .title3, weight: .medium)
    }

    /// モノスペースフォント（時間表示用）
    func monospaceFont() -> some View {
        scaledFont(style: .title3, weight: .medium, design: .monospaced)
    }

    // MARK: - アクセシビリティ対応

    /// アクセシビリティ対応フォント（制限なし）
    func accessibilityFont(
        style: Font.TextStyle,
        weight: Font.Weight = .regular,
        design: Font.Design = .rounded
    ) -> some View {
        self
            .font(.system(style, design: design, weight: weight))
            // アクセシビリティサイズの制限なし
    }

    /// アクセシビリティ対応フォント（サイズ指定）
    func accessibilityFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .rounded
    ) -> some View {
        self
            .font(.system(size: size, weight: weight, design: design))
            // アクセシビリティサイズの制限なし
    }
}

// MARK: - フォントサイズ定数
extension Font.TextStyle {
    /// フォントスタイルに対応するサイズ
    var size: CGFloat {
        switch self {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        @unknown default: return 17
        }
    }
}