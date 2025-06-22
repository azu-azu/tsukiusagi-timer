import SwiftUI

struct QuietMoonView: View {
    private let title  = "Quiet Moon"
    private let height: CGFloat = 300
    private let paddingY: CGFloat = 60
    private let bodyText = MoonMessage.random().lines.joined(separator: "\n")

    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .glitter(size: 24, resourceName: "gold")
                .frame(maxWidth: .infinity)

            ZStack {
                // スクロール背景（透明）＋hit testing 無効
                ScrollView(.vertical, showsIndicators: false) {
                    Color.clear
                        .frame(height: height)
                }
                .frame(height: height)
                .allowsHitTesting(false)

                // 実体：SelectableTextView
                SelectableTextView(
                    text: bodyText,
                    font: avenirNextUIFont(size: 18, weight: .regular, design: .monospaced),
                    textColor: .white
                )

                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                .frame(height: height)
            }

            Spacer()
        }
        .padding(.top, paddingY)
    }
}
