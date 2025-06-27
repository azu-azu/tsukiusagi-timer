import SwiftUI

// 固定スター
struct StaticStarsView: View {
    let size: CGSize
    let safeAreaInsets: EdgeInsets
    private let starCount = 20

    struct Star: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let color: Color
        let opacity: Double
    }

    @State private var stars: [Star] = []

    var body: some View {
        if size.width > 0 && size.height > 0 {
            ZStack(alignment: .bottom) {
                ForEach(stars) { star in
                    Circle()
                        .fill(star.color.opacity(star.opacity))
                        .frame(width: star.size)
                        .opacity(0.8)
                        .position(x: star.x, y: star.y)
                }
            }
            .onAppear {
                if stars.isEmpty {
                    stars = (0..<starCount).map { _ in
                        Star(
                            x: .random(in: 0...size.width),
                            y: .random(in: 0...(size.height + safeAreaInsets.bottom)),
                            size: .random(in: 2...6),
                            color: Color.yellow,
                            opacity: .random(in: 0.15...0.8)
                        )
                    }
                }
            }
        } else {
            EmptyView()
        }
    }
}