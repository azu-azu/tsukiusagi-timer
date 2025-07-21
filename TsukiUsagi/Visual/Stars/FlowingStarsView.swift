import SwiftUI

// １つの星を直進させる共通ビュー
struct LinearMovingStar: View {
    let size: CGFloat
    let start: CGPoint
    let end: CGPoint
    let duration: Double
    let delay: Double

    @State private var pos: CGPoint

    init(size: CGFloat, start: CGPoint, end: CGPoint, duration: Double, delay: Double) {
        self.size = size
        self.start = start
        self.end = end
        self.duration = duration
        self.delay = delay
        _pos = State(initialValue: start)
    }

    var body: some View {
        Circle()
            .fill(Color.white.opacity(1.0)) // opacity固定
            .frame(width: size, height: size)
            .position(pos)
            .onAppear {
                let animate = {
                    pos = end
                }
                if delay < 0 {
                    let progress = min(max(-delay / duration, 0), 1)
                    pos = CGPoint(
                        x: start.x + (end.x - start.x) * progress,
                        y: start.y + (end.y - start.y) * progress
                    )
                    withAnimation(
                        .linear(duration: duration * (1 - progress))
                            .repeatForever(autoreverses: false)
                    ) {
                        animate()
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(
                            .linear(duration: duration)
                                .repeatForever(autoreverses: false)
                        ) {
                            animate()
                        }
                    }
                }
            }
    }
}

// FlowBand → StarSpawnArea
struct StarSpawnArea {
    let minXRatio: CGFloat
    let maxXRatio: CGFloat
    let minYRatio: CGFloat
    let maxYRatio: CGFloat
}

// FlowingStarsModel → FlowingStarsGenerator
class FlowingStarsGenerator: ObservableObject {
    // Star → FlowingStar
    struct FlowingStar: Identifiable {
        let id = UUID()
        let startRatio: CGPoint // 0〜1
        let endRatio: CGPoint // 0〜1
        let size: CGFloat
        let color: Color
        let opacity: Double
        let duration: Double
        let delay: Double
    }

    @Published var stars: [FlowingStar] = []
    private let starCount: Int
    private let angle: Angle
    private let durationRange: ClosedRange<Double>
    private let sizeRange: ClosedRange<CGFloat>
    private let spawnArea: StarSpawnArea?
    private var lastSize: CGSize = .zero

    init(
        starCount: Int,
        angle: Angle,
        durationRange: ClosedRange<Double>,
        sizeRange: ClosedRange<CGFloat>,
        spawnArea: StarSpawnArea?) {
            self.starCount = starCount
            self.angle = angle
            self.durationRange = durationRange
            self.sizeRange = sizeRange
            self.spawnArea = spawnArea
            generateStars(for: .zero)
    }

    func regenerateStars(for size: CGSize) {
        lastSize = size
        generateStars(for: size)
    }

    private func generateStars(for _: CGSize) {
        let areaToUse = spawnArea ?? Self.defaultSpawnArea(for: angle)
        let centerCount = min(10, starCount) // 最初に中央から生成する星の個数

        stars = (0 ..< starCount).map { i in
            // swiftlint:disable:next identifier_name
            // Issue #4: 一時変数用途の命名ルール明確化（2024年8月目標）
            // i: ループカウンタ（短いスコープのため許容）
            let (startRatio, endRatio): (CGPoint, CGPoint)

            // 呼び出し時の最初のみ、中央からも星を出現させる。中央が空く問題を回避するため
            if i < centerCount {
                // swiftlint:disable:next identifier_name
                // x, y: 中央付近の座標（数学的意味で許容）
                let x = CGFloat.random(in: 0.48 ... 0.52)
                let y = CGFloat.random(in: areaToUse.minYRatio ... areaToUse.maxYRatio)
                let start = CGPoint(x: x, y: y)
                // 角度にランダム性を追加（±5度の範囲でばらつかせる）
                let angleVariation = CGFloat.random(in: -5 ... 5) * .pi / 180
                let adjustedAngle = angle.radians + angleVariation
                let distance = CGFloat.random(in: 1.0 ... 1.4) // 距離もランダム化
                let deltaX = cos(adjustedAngle) * distance
                let deltaY = sin(adjustedAngle) * distance
                let end = CGPoint(x: start.x + deltaX, y: start.y + deltaY)
                startRatio = start
                endRatio = end
            } else {
                (startRatio, endRatio) = Self.generateStartAndEndPoints(for: areaToUse, angle: angle.radians)
            }
            return FlowingStar(
                startRatio: startRatio,
                endRatio: endRatio,
                size: .random(in: sizeRange),
                color: Color.white,
                opacity: .random(in: 0.3 ... 0.8),
                duration: .random(in: durationRange),
                delay: .random(in: -15 ... 15)
            )
        }
    }

    // デフォルトのスポーンエリア範囲（angleごとに自動設定）
    private static func defaultSpawnArea(for angle: Angle) -> StarSpawnArea {
        let deg = angle.degrees.truncatingRemainder(dividingBy: 360)
        if deg == 90 || deg == -270 { // 下向き
            return StarSpawnArea(minXRatio: -0.1, maxXRatio: 1.1, minYRatio: -0.2, maxYRatio: 0.1)
        } else if deg == -90 || deg == 270 { // 上向き
            return StarSpawnArea(minXRatio: -0.1, maxXRatio: 1.1, minYRatio: 0.9, maxYRatio: 1.2)
        } else if deg == 0 { // 右向き
            return StarSpawnArea(minXRatio: -0.1, maxXRatio: 0.1, minYRatio: 0.0, maxYRatio: 1.0)
        } else if deg == 180 || deg == -180 { // 左向き
            return StarSpawnArea(minXRatio: 0.9, maxXRatio: 1.1, minYRatio: 0.0, maxYRatio: 1.0)
        } else { // 斜めなど
            return StarSpawnArea(minXRatio: -0.1, maxXRatio: 1.1, minYRatio: -0.1, maxYRatio: 1.1)
        }
    }

    // エリア内で開始・終了点を生成
    private static func generateStartAndEndPoints(
        for area: StarSpawnArea,
        angle: CGFloat,
        distance _: CGFloat = 1.2
    ) -> (CGPoint, CGPoint) {
        let startX = CGFloat.random(in: area.minXRatio ... area.maxXRatio)
        let startY = CGFloat.random(in: area.minYRatio ... area.maxYRatio)

        // 角度にランダム性を追加（±3度の範囲でばらつかせる）
        let angleVariation = CGFloat.random(in: -3 ... 3) * .pi / 180
        let adjustedAngle = angle + angleVariation

        // 距離もランダム化
        let randomDistance = CGFloat.random(in: 0.8 ... 1.6)

        let deltaX = cos(adjustedAngle) * randomDistance
        let deltaY = sin(adjustedAngle) * randomDistance
        let endX = startX + deltaX
        let endY = startY + deltaY
        return (CGPoint(x: startX, y: startY), CGPoint(x: endX, y: endY))
    }
}

struct FlowingStarsView: View {
    @StateObject private var generator: FlowingStarsGenerator
    @State private var lastSize: CGSize = .zero

    init(
        starCount: Int,
        angle: Angle = .degrees(90),
        durationRange: ClosedRange<Double> = 24...40,
        sizeRange: ClosedRange<CGFloat> = 2...4,
        spawnArea: StarSpawnArea? = nil,
        isAnimationActive: Bool = true
    ) {
        _generator = StateObject(wrappedValue: FlowingStarsGenerator(
            starCount: starCount,
            angle: angle,
            durationRange: durationRange,
            sizeRange: sizeRange,
            spawnArea: spawnArea
        ))
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let safeAreaInsets = geo.safeAreaInsets
            ZStack {
                ForEach(generator.stars) { star in
                    FlowingStarView(
                        star: star,
                        size: size,
                        safeAreaInsets: safeAreaInsets
                    )
                }
            }
            .ignoresSafeArea()
            .onChange(of: size) { _, newSize in
                if newSize != lastSize {
                    lastSize = newSize
                    generator.regenerateStars(for: newSize)
                }
            }
        }
    }
}

// AnimatedFlowingStar → FlowingStarView
struct FlowingStarView: View {
    let star: FlowingStarsGenerator.FlowingStar
    let size: CGSize
    let safeAreaInsets: EdgeInsets
    @State private var pos: CGPoint = .zero
    @State private var isVisible: Bool = false
    @State private var hasStarted: Bool = false

    var body: some View {
        Circle()
            .fill(star.color.opacity(star.opacity))
            .frame(width: star.size, height: star.size)
            .position(pos)
            .opacity(hasStarted ? 1 : (isVisible ? 1 : 0))
            .onAppear {
                let start = CGPoint(
                    x: size.width * star.startRatio.x,
                    y: safeAreaInsets.top + (
                        (size.height - safeAreaInsets.top - safeAreaInsets.bottom) * star.startRatio.y
                    )
                )
                let end = CGPoint(
                    x: size.width * star.endRatio.x,
                    y: safeAreaInsets.top + (
                        (size.height - safeAreaInsets.top - safeAreaInsets.bottom) * star.endRatio.y
                    )
                )
                // progressを分岐前に定義
                let progress: CGFloat
                if star.delay < 0 {
                    progress = min(max(-star.delay / star.duration, 0), 1)
                } else {
                    progress = 0
                }
                pos = CGPoint(
                    x: start.x + (end.x - start.x) * progress,
                    y: start.y + (end.y - start.y) * progress
                )

                let animate = {
                    pos = end
                }

                if star.delay < 0 {
                    isVisible = true
                    hasStarted = true
                    withAnimation(
                        .linear(duration: star.duration * (1 - progress))
                            .repeatForever(autoreverses: false)
                    ) {
                        animate()
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + star.delay) {
                        isVisible = true
                        hasStarted = true
                        withAnimation(
                            .linear(duration: star.duration)
                                .repeatForever(autoreverses: false)
                        ) {
                            animate()
                        }
                    }
                }
            }
    }
}

// 例: FlowingStarsView(starCount: 50, angle: .degrees(90), durationRange: 24...40, sizeRange: 2...4, band: nil)
// のようにstarCountや各種パラメータを指定可能
