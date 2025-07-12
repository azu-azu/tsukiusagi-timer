import SwiftUI

// 固定スター
struct StaticStarsView: View {
    let starCount: Int

    struct Star: Identifiable {
        let id = UUID()
        let xRatio: CGFloat
        let yRatio: CGFloat
        let size: CGFloat
        let color: Color
        let opacity: Double
    }

    @State private var stars: [Star] = []

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let safeAreaInsets = geo.safeAreaInsets
            ZStack {
                ForEach(stars) { star in
                    Circle()
                        .fill(star.color.opacity(star.opacity))
                        .frame(width: star.size, height: star.size)
                        .opacity(0.6)
                        .position(
                            x: size.width * star.xRatio,
                            y: safeAreaInsets.top + (
                                (size.height - safeAreaInsets.top - safeAreaInsets.bottom) * star.yRatio
                            )
                        )
                }
            }
            .ignoresSafeArea()
            .onAppear {
                if stars.isEmpty {
                    stars = (0 ..< starCount).map { _ in
                        Star(
                            xRatio: .random(in: 0 ... 1),
                            yRatio: .random(in: 0 ... 1),
                            size: .random(in: 2 ... 6),
                            color: Color.yellow,
                            opacity: .random(in: 0.15 ... 0.8)
                        )
                    }
                }
            }
        }
    }
}
