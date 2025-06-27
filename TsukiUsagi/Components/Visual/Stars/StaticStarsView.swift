import SwiftUI

// 固定スター
struct StaticStarsView: View {
    let size: CGSize
    let safeAreaInsets: EdgeInsets
    var body: some View {
        if size.width > 0 && size.height > 0 {
            ZStack(alignment: .bottom) {
                // ★ 星をシンプルに散らす
                ForEach(0..<20) { _ in
                    Circle()
                        .fill(Color.yellow.opacity(.random(in: 0.15...0.8)))
                        .frame(width: .random(in: 2...6))
                        .opacity(0.8)
                        .position(
                            x: .random(in: 0...size.width),
                            y: .random(in: 0...(size.height + safeAreaInsets.bottom))
                        )
                }
            }
        } else {
            EmptyView()
        }
    }
}