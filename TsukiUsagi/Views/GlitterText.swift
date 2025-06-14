import SwiftUI
import SDWebImageSwiftUI

struct GlitterText: View {
    let text: String

    var body: some View {
        AnimatedImage(url: Bundle.main.url(forResource: "blue", withExtension: "gif"))
            .resizable()
            .scaledToFill()
            .mask(
                Text(text)
                    .font(.system(size: 48, weight: .bold))
            )
            .frame(width: 300, height: 80)
            .clipped()
    }
}

#Preview {
    GlitterText(text: "studying")
}
