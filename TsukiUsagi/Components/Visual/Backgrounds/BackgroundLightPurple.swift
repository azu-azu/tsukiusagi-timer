import SwiftUI

struct BackgroundLightPurple: View {
	var body: some View {
		LinearGradient(
			gradient: Gradient(stops: [
				.init(color: Color(red: 0.10, green: 0.08, blue: 0.18), location: 0.0),
				.init(color: Color(red: 0.18, green: 0.13, blue: 0.30), location: 0.4),
				.init(color: Color(red: 0.30, green: 0.25, blue: 0.45), location: 0.8),
				.init(color: Color(red: 0.42, green: 0.36, blue: 0.60), location: 1.0)
			]),
			startPoint: .top,
			endPoint: .bottom
		)
		.ignoresSafeArea()
	}
}

#Preview {
	BackgroundLightPurple()
}