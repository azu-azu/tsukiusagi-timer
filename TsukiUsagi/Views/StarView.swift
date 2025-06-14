import SwiftUI

struct StarView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            // ★ 星をシンプルに散らす
            ForEach(0..<20) { i in
                Circle()
                    .fill(Color.white.opacity(.random(in: 0.15...0.8)))
                    .frame(width: .random(in: 2...6))
                    .position(
                        x: .random(in: 0...UIScreen.main.bounds.width),
						y: .random(in: 0...UIScreen.main.bounds.height * 0.7)
                    )
            }
        }
    }
}
