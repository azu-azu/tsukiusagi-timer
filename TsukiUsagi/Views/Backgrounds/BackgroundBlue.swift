import SwiftUI

struct BackgroundBlue: View {
	var body: some View {
		LinearGradient(
			gradient: Gradient(colors: [Color(hex: "#000088"), Color(hex: "#0000FF").opacity(0.8)]),
			startPoint: .top,
			endPoint: .bottom
		)
		.edgesIgnoringSafeArea(.all)
	}
}

#Preview {
	BackgroundBlue()
}