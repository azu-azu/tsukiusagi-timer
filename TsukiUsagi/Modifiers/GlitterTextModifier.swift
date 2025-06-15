import SwiftUI
import SDWebImageSwiftUI

// Modifier 本体
private struct GlitterTextModifier: ViewModifier {
    var font: Font

    func body(content: Content) -> some View {
        // content は Text を想定
        content
            .font(font)
            .overlay(
                AnimatedImage(
                    url: Bundle.main.url(forResource: "black_yellow", withExtension: "gif"))
                    .resizable()
                    .scaledToFill()
            )
            .mask(
                content.font(font)      // content は Text なので OK
            )
            .fixedSize()
    }
}

// 糖衣拡張
extension Text {
    /// 文字に GIF グリッターを被せる
    func glitter(font: Font = .custom("AvenirNext-Bold", size: 36)) -> some View {
        modifier(GlitterTextModifier(font: font))
    }
}
