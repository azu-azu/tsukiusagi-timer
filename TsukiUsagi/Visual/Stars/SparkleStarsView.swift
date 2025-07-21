import SwiftUI

// MARK: - キラッと光る 1 粒

struct SparkleStar: View {
    // 角度をランダムに回して “菱形” に見せるだけ
    @State private var scale: CGFloat = 0
    let position: CGPoint
    let color: Color
    let size: CGFloat
    let lifetime: Double // 秒

    var body: some View {
        Rectangle() // 正方形を 45° 回転で菱形
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [color, .clear]),
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(45))
            .scaleEffect(scale)
            .position(position)
            .onAppear {
                withAnimation(.easeOut(duration: lifetime * 0.4)) { scale = 1 }
                // 消えるアニメ
                withAnimation(
                    .easeIn(duration: lifetime * 0.6)
                        .delay(lifetime * 0.4)
                ) {
                    scale = 0
                }
            }
    }
}

// MARK: - ランダムに “ポンっ” と出る星群

struct SparkleStarsView: View {
    @State private var stars: [SparkleSpec] = []

    private let screen = UIScreen.main.bounds
    private let colors: [Color] = [.yellow, .mint, .orange, .white.opacity(0.9)]

    var body: some View {
        ZStack {
            ForEach(stars) { spec in
                SparkleStar(
                    position: spec.position,
                    color: spec.color,
                    size: spec.size,
                    lifetime: spec.lifetime
                )
            }
        }
        .ignoresSafeArea()
        .onAppear { launchTimer() }
    }

    // MARK: - タイマーで一定間隔ごとにパッと発生

    private func launchTimer() {
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            // 少しだけ同時に出す
            let burst = Int.random(in: 2 ... 5)
            for _ in 0 ..< burst {
                stars.append(randomSpec())
            }
            // 破棄（メモリリーク防止）
            let now = Date()
            stars.removeAll { now.timeIntervalSince($0.birth) > $0.lifetime }
        }
    }

    // 乱数で 1 スター仕様
    private func randomSpec() -> SparkleSpec {
        SparkleSpec(
            color: colors.randomElement()!,
            position: CGPoint(
                x: .random(in: -40 ... screen.width + 40),
                y: .random(in: -40 ... screen.height + 40)
            ),
            size: .random(in: 12 ... 26),
            lifetime: .random(in: 0.6 ... 1.0)
        )
    }
}

// ⭐️ 内部データ
private struct SparkleSpec: Identifiable {
    let id = UUID()
    let color: Color
    let position: CGPoint
    let size: CGFloat
    let lifetime: Double
    let birth = Date()
}
