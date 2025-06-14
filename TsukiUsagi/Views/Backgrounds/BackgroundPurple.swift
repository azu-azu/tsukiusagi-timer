import SwiftUI

struct BackgroundPurple: View {
	var body: some View {
		LinearGradient(
			gradient: Gradient(colors: [Color(hex: "#330066"), Color(hex: "#6600FF").opacity(0.8)]),
			startPoint: .top,
			endPoint: .bottom
		)
		.edgesIgnoringSafeArea(.all)
	}
}

#Preview {
	BackgroundPurple()
}