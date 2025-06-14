import SwiftUI
import SDWebImageSwiftUI

struct GlitterText: View {
    let text: String
    var font: Font = .custom("AvenirNext-Bold", size: 36)
	// var font: Font = .custom("HelveticaNeue-Bold", size: 30)

    var body: some View {
        // ① ベースとなる Text（レイアウト基準）
        Text(text)
            .font(font)
            .overlay(                // ② 上に GIF を被せ
                AnimatedImage(
                    url: Bundle.main.url(forResource: "black_yellow",
                                        withExtension: "gif"))
                    .resizable()
                    .scaledToFill()
//                    .opacity(0.35)
//                    .blur(radius: 0.4)
//                    .saturation(0.85)
                    .scaledToFill()   // 文字より大きく敷き詰め
            )
            .mask(                   // ③ “文字形” をマスクに
                Text(text).font(font)
            )
            .fixedSize()             // ← 文字の実サイズだけに収まる！
    }
}
