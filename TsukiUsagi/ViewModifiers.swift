//
//  ViewModifiers.swift
//  TsukiUsagi
//
//  フォントを使うための共通モディファイア
//

// .titleWhiteBold()
// .titleWhiteBold(size: 32, design: .rounded)
// .titleWhiteBold(design: .serif)
// .titleWhiteBold(size: 18, design: .monospaced)

import SwiftUI

// MARK: - 汎用 “白＋Bold” モディファイア
private struct TitleWhiteBoldModifier: ViewModifier {
    let size:   CGFloat
    let design: Font.Design     // ← ここが可変！

    func body(content: Content) -> some View {
        content
            .font(.system(size: size,
                        weight: .bold,
                        design: design))
            .foregroundColor(.white)
    }
}

// MARK: - シンタックスシュガー
extension View {

    /// タイトル用（白・Bold）サイズ＆デザイン可変
    /// - Parameters:
    ///   - size: フォントサイズ (pt)。省略＝title3相当 (20pt)
    ///   - design: `.default`, `.rounded`, `.serif`, `.monospaced` など
    func titleWhiteBold(
        size   : CGFloat?      = nil,
        design : Font.Design   = .default
    ) -> some View {
        self.modifier(
            TitleWhiteBoldModifier(
                size: size ?? Font.TextStyle.title3.size,
                design: design
            )
        )
    }
}

// MARK: - TextStyle → サイズ変換
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




