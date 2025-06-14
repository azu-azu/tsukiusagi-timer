import SwiftUI

struct BackgroundLightPurple: View {
	var body: some View {
		LinearGradient(
			gradient: Gradient(colors: [Color(hex: "#9966cc"), Color(hex: "#cc99ff").opacity(0.8)]),
			startPoint: .top,
			endPoint: .bottom
		)
		.edgesIgnoringSafeArea(.all)
	}
}

#Preview {
	BackgroundLightPurple()
}