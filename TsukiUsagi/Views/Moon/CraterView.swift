import SwiftUI

/// 🌑 月面にちょこっと置くクレーター 3 個セット
struct CraterCluster: View {

	// 全体を縮小したい時用に scale を持たせとくと便利
	var scale: CGFloat = 1.0
	var opacity: Double = 0.05

	var body: some View {
		ZStack {   // Group と同じ効果。ZStack の方が拡張ラク
			Circle()
				.fill(Color.white.opacity(opacity))
				.frame(width: 20, height: 20)
				.offset(x: -40, y: 10)

			Circle()
				.fill(Color.white.opacity(opacity))
				.frame(width: 14, height: 14)
				.offset(x:  -30, y: -25)

			Circle()
				.fill(Color.white.opacity(opacity * 0.8))
				.frame(width: 10, height: 10)
				.offset(x: -20, y: 25)
		}
		.scaleEffect(scale)   // 好きな倍率で呼び出せる
	}
}
