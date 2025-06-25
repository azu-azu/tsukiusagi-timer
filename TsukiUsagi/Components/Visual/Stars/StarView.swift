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
            .fill(Color.white.opacity(.random(in: 0.25...0.9)))
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

// 🌠流れ星を呼び出す
// 上から下：FlowingStarsView(mode: .vertical(direction: .down)).allowsHitTesting(false)
// 下から上：FlowingStarsView(mode: .vertical(direction: .up)).allowsHitTesting(false)
// 左上→右下へ：FlowingStarsView(mode: .diagonal(angle: .pi / 4))
// 右上→左下へ：FlowingStarsView(mode: .diagonal(angle: 3 * .pi / 4))

// 斜めにライン状に流す場合
// FlowingStarsView(
//     mode: .diagonal(
//         angle: 3 * .pi / 4,
//         band: CGRect(
//             x: UIScreen.main.bounds.width - 100,
//             y: 0,
//             width: 100,
//             height: 100
//         )
//     ),
//     count: 40
// )

// FlowingStarsView(mode: ..., count: 50) のようにcount指定も可能
struct FlowingStarsView: View {
    enum Mode {
        case vertical(direction: Direction)
        case diagonal(angle: Double, band: CGRect? = nil)
        case custom(startPoint: () -> CGPoint, endPoint: (CGPoint) -> CGPoint)
    }
    enum Direction { case down, up }

    let mode: Mode
    let count: Int
    let maxDelay: Double
    let durationRange: ClosedRange<Double>
    let sizeRange: ClosedRange<CGFloat>

    private let screen = UIScreen.main.bounds

    init(
        mode: Mode,
        count: Int = 70,
        maxDelay: Double = 20,
        durationRange: ClosedRange<Double> = 24...40,
        sizeRange: ClosedRange<CGFloat> = 2...4
    ) {
        self.mode = mode
        self.count = count
        self.maxDelay = maxDelay
        self.durationRange = durationRange
        self.sizeRange = sizeRange
    }

    var body: some View {
        ForEach(0..<count, id: \.self) { _ in
            let (start, end): (CGPoint, CGPoint) = {
                switch mode {
                case .vertical(let direction):
                    let x = CGFloat.random(in: 0...screen.width)
                    let startY = direction == .down ? -20 : screen.height + 20
                    let endY = direction == .down ? screen.height + 20 : -20
                    return (CGPoint(x: x, y: startY), CGPoint(x: x, y: endY))
                case .diagonal(let angle, let band):
                    let startX: CGFloat
                    let startY: CGFloat
                    if let band = band {
                        startX = CGFloat.random(in: band.minX...band.maxX)
                        startY = CGFloat.random(in: band.minY...band.maxY)
                    } else {
                        startX = CGFloat.random(in: 0...screen.width)
                        startY = CGFloat.random(in: 0...screen.height)
                    }
                    let length: CGFloat = 300 // 斜めに進む距離
                    let endX = startX + cos(angle) * length
                    let endY = startY + sin(angle) * length
                    return (CGPoint(x: startX, y: startY), CGPoint(x: endX, y: endY))
                case .custom(let startPoint, let endPoint):
                    let s = startPoint()
                    let e = endPoint(s)
                    return (s, e)
                }
            }()
            AnimatedStar(
                size: .random(in: sizeRange),
                start: start,
                end: end,
                duration: .random(in: durationRange),
                delay: .random(in: -maxDelay...maxDelay)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

