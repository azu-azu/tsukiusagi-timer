import SwiftUI

// 固定スター
struct StarView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            // ★ 星をシンプルに散らす
            ForEach(0..<20) { i in
                Circle()
                    .fill(Color.yellow.opacity(.random(in: 0.15...0.8)))
                    .frame(width: .random(in: 2...6))
                    .opacity(0.6)
                    .position(
                        x: .random(in: 0...UIScreen.main.bounds.width),
						y: .random(in: 0...UIScreen.main.bounds.height * 0.7)
                    )
            }
        }
    }
}

// １つの星を直進させる共通ビュー
struct AnimatedStar: View {
    let size: CGFloat
    let startX: CGFloat         // 横位置はそのままランダム
    let startY: CGFloat         // 画面外（上 or 下）
    let endY: CGFloat
    let duration: Double

    // ⭐ 初期化時に「画面内のどこか」を乱数でセット
    @State private var yPos: CGFloat = .random(in: 0...UIScreen.main.bounds.height)

    var body: some View {
        Circle()
            .fill(Color.white.opacity(.random(in: 0.25...0.9)))
            .frame(width: size, height: size)
            .position(x: startX, y: yPos)
            .onAppear {
                // 1 周目は yPos が画面内の好きな位置 → endY へ
                withAnimation(.linear(duration: duration)
                                .repeatForever(autoreverses: false)) {
                    yPos = endY
                }
            }
    }
}


// 上から下へ
struct FallingStarsView: View {
    private let screen = UIScreen.main.bounds
    private let count  = 40        // 個数はお好み

    var body: some View {
        ForEach(0..<count, id: \.self) { _ in
            AnimatedStar(
                size: .random(in: 2...4),
                startX: .random(in: 0...screen.width), // ← 横位置
                startY: -20,                          // ← 画面外ちょい上
                endY: screen.height + 20,             // ← 画面外ちょい下
                duration: .random(in: 24...40)        // ← 速さ（大きいと遅い）
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

// 下から上へ
struct RisingStarsView: View {
    private let screen = UIScreen.main.bounds
    private let count  = 35

    var body: some View {
        ForEach(0..<count, id: \.self) { _ in
            AnimatedStar(
                size: .random(in: 2...4),
                startX: .random(in: 0...screen.width),
                startY: screen.height + 20,           // ← 画面外ちょい下
                endY: -20,                            // ← 画面外ちょい上
                duration: .random(in: 24...40)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}



// 使い方：ZStack で重ねるだけ
/*
ZStack {
    StarView()            // ★ 今までの固定背景
    FallingStarsView()    // ↓ 降る星
    RisingStarsView()     // ↑ 浮く星
    // ここに月・タイマーなど他の UI
}
*/