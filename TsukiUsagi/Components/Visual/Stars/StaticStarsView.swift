import SwiftUI

// 固定スター
struct StaticStarsView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            // ★ 星をシンプルに散らす
            ForEach(0..<20) { _ in
                Circle()
                    .fill(Color.yellow.opacity(.random(in: 0.15...0.8)))
                    .frame(width: .random(in: 2...6))
                    .opacity(0.8)
                    .position(
                        x: .random(in: 0...UIScreen.main.bounds.width),
                        y: .random(in: 0...UIScreen.main.bounds.height * 0.7)
                    )
            }
        }
    }
}