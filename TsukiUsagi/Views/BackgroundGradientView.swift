import SwiftUI

struct BackgroundGradientView: View {
	var body: some View {
		LinearGradient(
			// 青みがかった色 locationは開始位置
			gradient: Gradient(stops: [
				.init(color: Color(hex: "#161929"), location: 0.6),
				.init(color: Color(hex: "#1b2735"), location: 0.8),
				.init(color: Color(hex: "#1b2d42"), location: 1.0)
			]),
			
			// 紫
			//gradient: Gradient(stops: [
			//	.init(color: Color(red: 0.02, green: 0.02, blue: 0.07), location: 0.0),   // 深い紺
			//	.init(color: Color(red: 0.08, green: 0.05, blue: 0.15), location: 0.3),   // ほんのり紫
			//	.init(color: Color(red: 0.14, green: 0.08, blue: 0.25), location: 0.6),   // 星の背景ぽい
			//	.init(color: Color(red: 0.20, green: 0.10, blue: 0.35), location: 1.0)    // 月の余韻と調和
			//]),

			// 明るい紫バージョン
			// gradient: Gradient(stops: [
			// 	.init(color: Color(red: 0.10, green: 0.08, blue: 0.18), location: 0.0),
			// 	.init(color: Color(red: 0.18, green: 0.13, blue: 0.30), location: 0.4),
			// 	.init(color: Color(red: 0.30, green: 0.25, blue: 0.45), location: 0.8),
			// 	.init(color: Color(red: 0.42, green: 0.36, blue: 0.60), location: 1.0)
			// ]),
			startPoint: .top,
			endPoint: .bottom
		)
		.ignoresSafeArea()
	}
}
