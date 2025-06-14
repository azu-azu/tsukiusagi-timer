import SwiftUI

struct BackgroundBlue: View {
	var body: some View {
		LinearGradient(
			gradient: Gradient(stops: [
				.init(color: Color(hex: "#161929"), location: 0.6),
				.init(color: Color(hex: "#1b2735"), location: 0.8),
				.init(color: Color(hex: "#1b2d42"), location: 1.0)
			]),
			startPoint: .top,
			endPoint: .bottom
		)
		.ignoresSafeArea()
	}
}

#Preview {
	BackgroundBlue()
}