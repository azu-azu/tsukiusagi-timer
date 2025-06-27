import SwiftUI

// １つの星を直進させる共通ビュー
struct AnimatedStar: View {
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
                    withAnimation(.linear(duration: duration * (1 - progress)).repeatForever(autoreverses: false)) {
                        animate()
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                            animate()
                        }
                    }
                }
            }
    }
}

struct FlowBand {
    let minXRatio: CGFloat
    let maxXRatio: CGFloat
    let minYRatio: CGFloat
    let maxYRatio: CGFloat
}

// --- FlowingStarsModel ---
class FlowingStarsModel: ObservableObject {
    struct Star: Identifiable {
        let id = UUID()
        let startRatio: CGPoint // 0〜1
        let endRatio: CGPoint   // 0〜1
        let size: CGFloat
        let color: Color
        let opacity: Double
        let duration: Double
        let delay: Double
    }

    @Published var stars: [Star] = []
    private let starCount: Int
    private let angle: Angle
    private let durationRange: ClosedRange<Double>
    private let sizeRange: ClosedRange<CGFloat>
    private let band: FlowBand?
    private var lastSize: CGSize = .zero

    init(starCount: Int, angle: Angle, durationRange: ClosedRange<Double>, sizeRange: ClosedRange<CGFloat>, band: FlowBand?) {
        self.starCount = starCount
        self.angle = angle
        self.durationRange = durationRange
        self.sizeRange = sizeRange
        self.band = band
        generateStars(for: .zero)
    }

    func regenerateStars(for size: CGSize) {
        lastSize = size
        generateStars(for: size)
    }

    private func generateStars(for size: CGSize) {
        let bandToUse = band ?? Self.defaultBand(for: angle)
        let centerCount = min(10, starCount) // 最初に中央から複数を生成する
        stars = (0..<starCount).map { i in
            let (startRatio, endRatio): (CGPoint, CGPoint)
            if i < centerCount {
                // 中央付近からスタート（x:0.48〜0.52, y:バンドのminYRatio）
                let x = CGFloat.random(in: 0.48...0.52)
                let y = bandToUse.minYRatio
                let start = CGPoint(x: x, y: y)
                let angleRad = angle.radians
                let distance: CGFloat = 1.2
                let deltaX = cos(angleRad) * distance
                let deltaY = sin(angleRad) * distance
                let end = CGPoint(x: start.x + deltaX, y: start.y + deltaY)
                startRatio = start
                endRatio = end
            } else {
                (startRatio, endRatio) = Self.generateStartAndEndPoints(for: bandToUse, angle: angle.radians)
            }
            return Star(
                startRatio: startRatio,
                endRatio: endRatio,
                size: .random(in: sizeRange),
                color: Color.white,
                opacity: .random(in: 0.3...0.7),
                duration: .random(in: durationRange),
                delay: .random(in: -10...10)
            )
        }
    }

    // デフォルトのバンド範囲（angleごとに自動設定）
    private static func defaultBand(for angle: Angle) -> FlowBand {
        let deg = angle.degrees.truncatingRemainder(dividingBy: 360)
        if deg == 90 || deg == -270 { // 下向き
            return FlowBand(minXRatio: 0.0, maxXRatio: 1.0, minYRatio: -0.1, maxYRatio: 0.0)
        } else if deg == -90 || deg == 270 { // 上向き
            return FlowBand(minXRatio: 0.0, maxXRatio: 1.0, minYRatio: 1.0, maxYRatio: 1.1)
        } else if deg == 0 { // 右向き
            return FlowBand(minXRatio: 0.0, maxXRatio: 0.0, minYRatio: 0.1, maxYRatio: 0.9)
        } else if deg == 180 || deg == -180 { // 左向き
            return FlowBand(minXRatio: 1.0, maxXRatio: 1.0, minYRatio: 0.1, maxYRatio: 0.9)
        } else { // 斜めなど
            return FlowBand(minXRatio: 0.1, maxXRatio: 0.9, minYRatio: 0.1, maxYRatio: 0.9)
        }
    }

    // バンド内で開始・終了点を生成
    private static func generateStartAndEndPoints(for band: FlowBand, angle: CGFloat, distance: CGFloat = 1.2) -> (CGPoint, CGPoint) {
        let startX = CGFloat.random(in: band.minXRatio...band.maxXRatio)
        let startY = CGFloat.random(in: band.minYRatio...band.maxYRatio)
        let deltaX = cos(angle) * distance
        let deltaY = sin(angle) * distance
        let endX = startX + deltaX
        let endY = startY + deltaY
        return (CGPoint(x: startX, y: startY), CGPoint(x: endX, y: endY))
    }
}

struct FlowingStarsView: View {
    let starCount: Int
    let angle: Angle
    let durationRange: ClosedRange<Double>
    let sizeRange: ClosedRange<CGFloat>
    let band: FlowBand?

    @StateObject private var model: FlowingStarsModel
    @State private var lastSize: CGSize = .zero

    init(starCount: Int, angle: Angle, durationRange: ClosedRange<Double>, sizeRange: ClosedRange<CGFloat>, band: FlowBand?) {
        self.starCount = starCount
        self.angle = angle
        self.durationRange = durationRange
        self.sizeRange = sizeRange
        self.band = band
        _model = StateObject(wrappedValue: FlowingStarsModel(starCount: starCount, angle: angle, durationRange: durationRange, sizeRange: sizeRange, band: band))
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let safeAreaInsets = geo.safeAreaInsets
            ZStack {
                ForEach(model.stars) { star in
                    AnimatedFlowingStar(
                        star: star,
                        size: size,
                        safeAreaInsets: safeAreaInsets
                    )
                }
            }
            .ignoresSafeArea()
            .onChange(of: size) { oldSize, newSize in
                if newSize != lastSize {
                    lastSize = newSize
                    model.regenerateStars(for: newSize)
                }
            }
        }
    }
}

struct AnimatedFlowingStar: View {
    let star: FlowingStarsModel.Star
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
                    y: safeAreaInsets.top + (size.height - safeAreaInsets.top - safeAreaInsets.bottom) * star.startRatio.y
                )
                let end = CGPoint(
                    x: size.width * star.endRatio.x,
                    y: safeAreaInsets.top + (size.height - safeAreaInsets.top - safeAreaInsets.bottom) * star.endRatio.y
                )
                pos = start
                let animate = {
                    pos = end
                }
                if star.delay < 0 {
                    let progress = min(max(-star.delay / star.duration, 0), 1)
                    pos = CGPoint(
                        x: start.x + (end.x - start.x) * progress,
                        y: start.y + (end.y - start.y) * progress
                    )
                    isVisible = true
                    hasStarted = true
                    withAnimation(.linear(duration: star.duration * (1 - progress)).repeatForever(autoreverses: false)) {
                        animate()
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + star.delay) {
                        isVisible = true
                        hasStarted = true
                        withAnimation(.linear(duration: star.duration).repeatForever(autoreverses: false)) {
                            animate()
                        }
                    }
                }
            }
    }
}

// 例: FlowingStarsView(starCount: 50, angle: .degrees(90), durationRange: 24...40, sizeRange: 2...4, band: nil) のようにstarCountや各種パラメータを指定可能

