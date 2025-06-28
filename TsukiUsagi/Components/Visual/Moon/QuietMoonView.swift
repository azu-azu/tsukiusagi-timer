import SwiftUI

struct QuietMoonView: View {
    private let title  = "Quiet Moon"
    private let height: CGFloat = 300
    private let paddingY: CGFloat = 60
    private let bodyText = MoonMessage.random().lines.joined(separator: "\n")

    let size: CGSize
    let safeAreaInsets: EdgeInsets

    var body: some View {
        ZStack {
            // 既存のVStack内容
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
                    .frame(height: height)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                }
                Spacer()
            }
            .padding(.top, paddingY)

            // FlowingStarsViewをZStackの一番下に配置
            FlowingStarsView(
                starCount: 20,
                angle: .degrees(135),
                durationRange: 24...40,
                sizeRange: 2...4,

                spawnArea: nil // デフォルト値

                // spawnArea: StarSpawnArea(
                //     minXRatio: 0.0,  // 左端
                //     maxXRatio: 1.0,  // 右端
                //     minYRatio: -0.2, // より上から（画面外）
                //     maxYRatio: 0.0   // 画面上端
                // )

                // spawnArea: StarSpawnArea(
                //     minXRatio: 0.0,  // 左端
                //     maxXRatio: 1.0,  // 右端
                //     minYRatio: 0.8,  // 画面下部
                //     maxYRatio: 1.2   // より下から（画面外）
                // )
            )
            .ignoresSafeArea()
        }
    }
}
