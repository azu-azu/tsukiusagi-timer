//
//  ViewModifiers.swift
//  TsukiUsagi
//
//  フォントを使うための共通モディファイア
//

import SwiftUI
import UIKit

// （font関連ViewModifier拡張をすべて削除）

// シンタックスシュガー
extension View {
    /// タイトル用（白・Weight／デザイン可変）
    /// - Parameters:
    ///   - size:    フォントサイズ (pt)。nil＝title3相当 (20pt)
    ///   - weight:  `.regular`, `.medium`, `.bold` など（デフォルト `.bold`）
    ///   - design:  `.default`, `.rounded`, `.serif`, `.monospaced` など
    func titleWhite(
        size: CGFloat? = nil,
        weight: Font.Weight = .bold,
        design: Font.Design = .default
    ) -> some View {
        font(DesignTokens.Fonts.title)
            .foregroundColor(.white)
    }
}

// * AvenirNext White Modifiers
private struct AvenirNextWhiteModifier: ViewModifier {
    let size: CGFloat
    /// `.bold` なら "AvenirNext-Bold"、それ以外は "AvenirNext"
    let weight: Font.Weight

    func body(content: Content) -> some View {
        let fontName: String = (weight == .bold) ? "AvenirNext-Bold" : "AvenirNext"
        return content
            // swiftlint:disable:next forbidden-font-direct
            .font(
                .custom(fontName, size: size)
            )
            .foregroundColor(.white)
    }
}

// シンタックスシュガー
extension View {
    /// タイトル用（白・AvenirNext／太さ可変）
    /// - Parameters:
    ///   - size:   フォントサイズ (pt)。nil＝title3相当 (20pt)
    ///   - weight: `.regular` か `.bold`（デフォルト `.bold`）
    func titleWhiteAvenir(
        size: CGFloat? = nil,
        weight: Font.Weight = .bold
    ) -> some View {
        modifier(
            AvenirNextWhiteModifier(
                size: size ?? 20,
                weight: weight
            )
        )
    }
}

/// AvenirNext系のUIFontを生成
/// - Parameters:
///   - size: フォントサイズ
///   - weight: UIFont.Weight（.regular/.bold など）
///   - design: UIFontDescriptor.SystemDesign（.default/.monospaced など）
/// - Returns: UIFont
func avenirNextUIFont(size: CGFloat, weight: UIFont.Weight = .regular, design: UIFontDescriptor.SystemDesign = .default) -> UIFont {
    let fontName: String
    switch weight {
    case .bold:
        fontName = "AvenirNext-Bold"
    default:
        fontName = "AvenirNext-Regular"
    }
    guard let baseFont = UIFont(name: fontName, size: size) else {
        // swiftlint:disable:next discouraged-font-usage
        return UIFont.systemFont(ofSize: size, weight: weight) // [理由] AvenirNextが取得できない場合のフォールバック
    }
    // デザイン（monospaced等）を適用
    if let descriptor = baseFont.fontDescriptor.withDesign(design) {
        return UIFont(descriptor: descriptor, size: size)
    } else {
        return baseFont
    }
}
