// 使い方
// Text("Default").glitter()
// Text("Big").glitter(size: 60)
// Text("Custom").glitter(size: 40, fontName: "Futura-Bold")
// Text("Pink").glitter(resourceName: "gold")

import SwiftUI
import Kingfisher

// Modifier 本体
private struct GlitterTextModifier: ViewModifier {
    let font: Font
    let resourceName: String
    let resourceExt: String
    let size: CGFloat

    func body(content: Content) -> some View {
        let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExt)

        return content
            .font(font)
            .overlay(
                KFAnimatedImage(url)
                    .frame(height: size)
            )
            .mask(content.font(font))
    }
}

// Sugar extension for Text
extension Text {
    /// Adds a glitter GIF mask to the text.
    /// - Parameters:
    ///   - size:     Point size (default 36)
    ///   - fontName: Font family (default AvenirNext-Bold)
    ///   - resourceName: GIF file in the main bundle (default "gold")
    ///   - resourceExt:  File extension (default "gif")
    func glitter(
        size: CGFloat = 36,
        fontName: String = "AvenirNext-Bold",
        resourceName: String = "gold",
        resourceExt: String = "gif"
    ) -> some View {
        let customFont = Font.custom(fontName, size: size)
        return self.modifier(
            GlitterTextModifier(
                font: customFont,
                resourceName: resourceName,
                resourceExt: resourceExt,
                size: size
            )
        )
    }
}

// Text以外のViewにもキラキラエフェクトを重ねる
extension View {
    /// 任意のViewにキラキラエフェクトを重ねる
    func glitter(
        size: CGFloat = 36,
        resourceName: String = "gold",
        resourceExt: String = "gif"
    ) -> some View {
        let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExt)

        return overlay(
            KFAnimatedImage(url)
                .frame(width: size, height: size)
        )
    }
}
