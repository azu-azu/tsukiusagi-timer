import SwiftUI
import Foundation

struct BackgroundPurple: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(red: 0.02, green: 0.02, blue: 0.07), location: 0.0), // 深い紺
                .init(color: Color(red: 0.08, green: 0.05, blue: 0.15), location: 0.3), // ほんのり紫
                .init(color: Color(red: 0.14, green: 0.08, blue: 0.25), location: 0.6), // 星の背景ぽい
                .init(color: Color(red: 0.20, green: 0.10, blue: 0.35), location: 1.0) // 月の余韻と調和
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#Preview {
    BackgroundPurple()
}
