// 使い方
// Text("Default").glitter()
// Text("Big").glitter(size: 60)
// Text("Custom").glitter(size: 40, fontName: "Futura-Bold")
// Text("Pink").glitter(resourceName: "gold")

import SDWebImageSwiftUI
import SwiftUI

// Modifier 本体
private struct GlitterTextModifier: ViewModifier {
    let font: Font
    let resourceName: String // e.g. "black_yellow"
    let resourceExt: String // default "gif"

    func body(content: Content) -> some View {
        content
            .font(font)
            .overlay(
                AnimatedImage(
                    url: Bundle.main.url(
                        forResource: resourceName,
                        withExtension: resourceExt
                    )
                )
                .resizable()
                .scaledToFill()
            )
            .mask(content.font(font))
    }
}

// Sugar extension
extension Text {
    /// Adds a glitter GIF mask to the text.
    /// - Parameters:
    ///   - size:     Point size (default 36)
    ///   - fontName: Font family (default AvenirNext-Bold)
    ///   - resourceName: GIF file in the main bundle (default "black_yellow")
    ///   - resourceExt:  File extension (default "gif")
    func glitter(size: CGFloat = 36,
                 fontName: String = "AvenirNext-Bold",
                 resourceName: String = "black_yellow",
                 resourceExt: String = "gif") -> some View
    {
        let customFont = Font.custom(fontName, size: size)
        return modifier(
            GlitterTextModifier(font: customFont,
                                resourceName: resourceName,
                                resourceExt: resourceExt)
        )
    }
}

// Text以外のViewにもキラキラエフェクトを重ねる
extension View {
    /// 任意のViewにキラキラエフェクトを重ねる
    func glitter(size: CGFloat = 36, resourceName: String = "black_yellow", resourceExt: String = "gif") -> some View {
        overlay(
            AnimatedImage(
                url: Bundle.main.url(
                    forResource: resourceName,
                    withExtension: resourceExt
                )
            )
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
        )
    }
}
