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