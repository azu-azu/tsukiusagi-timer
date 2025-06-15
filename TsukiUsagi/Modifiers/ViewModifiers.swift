//
//  ViewModifiers.swift
//  TsukiUsagi
//
//  フォントを使うための共通モディファイア
//

// .titleWhite()
// .titleWhite(design: .rounded)
// .titleWhite(size: 32, design: .rounded)
// .titleWhite(size: 18, design: .monospaced)

import SwiftUI

// *汎用 system
private struct TitleWhiteModifier: ViewModifier {
    let size:   CGFloat

     // 可変
    let weight: Font.Weight
    let design: Font.Design

    func body(content: Content) -> some View {
        content
            .font(.system(size: size,
                        weight: weight,
                        design: design))
            .foregroundColor(.white)
    }
}

// シンタックスシュガー
extension View {
    /// タイトル用（白・Weight／デザイン可変）
    /// - Parameters:
    ///   - size:    フォントサイズ (pt)。nil＝title3相当 (20pt)
    ///   - weight:  `.regular`, `.medium`, `.bold` など（デフォルト `.bold`）
    ///   - design:  `.default`, `.rounded`, `.serif`, `.monospaced` など
    func titleWhite(
        size   : CGFloat?      = nil,
        weight : Font.Weight   = .bold,
        design : Font.Design   = .default
    ) -> some View {
        self.modifier(
            TitleWhiteModifier(
                size: size ?? Font.TextStyle.title3.size,
                weight: weight,
                design: design
            )
        )
    }
}

// TextStyle → サイズ変換
private extension Font.TextStyle {
    var size: CGFloat {
        switch self {
        case .largeTitle: return 34
        case .title:      return 28
        case .title2:     return 22
        case .title3:     return 20
        default:          return 17
        }
    }
}


// Text("Hello Avenir!")
//     .titleWhiteAvenir(size: 32, weight: .bold)
// Text("Regular Avenir")
//     .titleWhiteAvenir(size: 24, weight: .regular)

// * AvenirNext White Modifiers
private struct AvenirNextWhiteModifier: ViewModifier {
    let size: CGFloat
    /// `.bold` なら "AvenirNext-Bold"、それ以外は "AvenirNext"
    let weight: Font.Weight

    func body(content: Content) -> some View {
        let fontName: String = (weight == .bold) ? "AvenirNext-Bold" : "AvenirNext"
        return content
            .font(.custom(fontName, size: size))
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
        size  : CGFloat?    = nil,
        weight: Font.Weight = .bold
    ) -> some View {
        self.modifier(
            AvenirNextWhiteModifier(
                size: size ?? Font.TextStyle.title3.size,
                weight: weight
            )
        )
    }
}