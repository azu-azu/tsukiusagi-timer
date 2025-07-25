import SwiftUI

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var diamondPath = Path()
        let midX = rect.midX, midY = rect.midY
        diamondPath.move(to: CGPoint(x: midX, y: rect.minY)) // 上
        diamondPath.addLine(to: CGPoint(x: rect.maxX, y: midY)) // 右
        diamondPath.addLine(to: CGPoint(x: rect.midX, y: rect.maxY)) // 下
        diamondPath.addLine(to: CGPoint(x: rect.minX, y: midY)) // 左
        diamondPath.closeSubpath()
        return diamondPath
    }
}

struct SparkleDiamond: View {
    // 引数は今まで通り
    let position: CGPoint
    let size: CGFloat
    let color: Color
    let lifetime: Double

    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 1 // 追加: フェード用

    var body: some View {
        ZStack {
            // ① 外側グロー（ぼんやり）
            Diamond()
                .fill(color.opacity(0.25))
                .frame(width: size * 1.8, height: size * 1.8)
                .blur(radius: size * 0.3)

            // ② 本体グラデ（少し柔らかい）
            Diamond()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: color, location: 0.0),
                            .init(color: color, location: 0.15),
                            .init(color: color.opacity(0.2), location: 0.45),
                            .init(color: .clear, location: 1.0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)

            // ③ キワを光らせる細ライン
            Diamond()
                .stroke(Color.white.opacity(0.9), lineWidth: 1.0)
                .frame(width: size, height: size)
        }
        .scaleEffect(scale)
        .opacity(opacity) // 追加: フェード用
        .position(position)
        .compositingGroup() // レイヤーを1枚化
        .onAppear {
            withAnimation(.easeOut(duration: lifetime * 0.3)) { scale = 1 }
            withAnimation(.easeIn(duration: lifetime * 0.7)
                .delay(lifetime * 0.3)) { scale = 0 }
            withAnimation(.easeOut(duration: 1.2)
                .delay(lifetime * 0.3)) { opacity = 0 } // 余韻を長く
        }
        .blur(radius: 3)
    }
}

private struct SparkleSpec: Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGFloat
    let color: Color
    let lifetime: Double
    let birth = Date()
}

struct DiamondStarsOnceView: View {
    // ✨ 作りたい総数
    private let total = 250
    private let perOnce = 60 // 一回で何個までか

    // アニメーション終了時のコールバック
    var onFinished: (() -> Void)?

    @State private var stars: [SparkleSpec] = []
    @State private var generated = 0 // 今何個作ったか
    private let screen = UIScreen.main.bounds
    private let colors: [Color] = [.yellow]
    // private let colors: [Color] = [.yellow, .white] // 複数指定する場合

    // アニメーション全体の想定時間
    private var animationTotalTime: Double {
        // 星の生成間隔 * 総数 + 最後の星のライフタイム
        return 0.1 * Double(total / perOnce) + 0.3
    }

    var body: some View {
        ZStack {
            // swiftlint:disable:next identifier_name
            // Issue #4: 一時変数用途の命名ルール明確化（2024年8月目標）
            // s: SparkleSpecの短命な一時変数（forEach内のみ許容）
            ForEach(stars) { s in
                SparkleDiamond(
                    position: s.position,
                    size: s.size,
                    color: s.color,
                    lifetime: s.lifetime
                )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            launchTimer()

            // アニメーション完了タイミングでonFinishedを呼ぶ
            DispatchQueue.main.asyncAfter(deadline: .now() + animationTotalTime) {
                onFinished?()
            }
        }
    }

    private func launchTimer() {
        // N秒ごとにバラけて出現
        // swiftlint:disable:next identifier_name
        // t: Timerクロージャの一時変数（用途明示）
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { t in
            // 1 回あたり 何個か
            let burst = Int.random(in: 2 ... perOnce)
            for _ in 0 ..< burst where generated < total {
                stars.append(randomSpec())
                generated += 1
            }

            // 全部作り終えたらタイマー停止
            if generated >= total { t.invalidate() }
        }
    }

    private func randomSpec() -> SparkleSpec {
        SparkleSpec(
            position: CGPoint(
                x: .random(in: -40 ... screen.width + 40),
                y: .random(in: -40 ... screen.height + 40)
            ),
            size: .random(in: 80 ... 150),
            color: colors.randomElement()!,
            lifetime: .random(in: 0.1 ... 0.3) // 1 回光って終わり
        )
    }
}

// 継続するならこっち
struct DiamondStarsView: View {
    @State private var stars: [SparkleSpec] = []
    private let screen = UIScreen.main.bounds
    private let colors: [Color] = [.yellow, .white, .orange]

    var body: some View {
        ZStack {
            // swiftlint:disable:next identifier_name
            // s: SparkleSpecの短命な一時変数（forEach内のみ許容）
            ForEach(stars) { s in
                SparkleDiamond(
                    position: s.position,
                    size: s.size,
                    color: s.color,
                    lifetime: s.lifetime
                )
            }
        }
        .ignoresSafeArea()
        .onAppear { launchTimer() }
    }

    private func launchTimer() {
        // repeats:繰り返すかどうか
        // swiftlint:disable:next identifier_name
        // t: Timerクロージャの一時変数（用途明示）
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { _ in
            let count = Int.random(in: 30 ... 80) // ランダム数 repeatsの時
            // let count = 80
            for _ in 0 ..< count {
                stars.append(randomSpec())
            }
            // 古いやつ削除
            let now = Date()
            stars.removeAll { now.timeIntervalSince($0.birth) > $0.lifetime }
        }
    }

    private func randomSpec() -> SparkleSpec {
        SparkleSpec(
            position: CGPoint(
                x: .random(in: -40 ... screen.width + 40),
                y: .random(in: -40 ... screen.height + 40)
            ),

            size: .random(in: 40 ... 60), // 大きさ
            color: colors.randomElement()!,
            lifetime: .random(in: 0.1 ... 0.5) // 速さ
        )
    }
}
