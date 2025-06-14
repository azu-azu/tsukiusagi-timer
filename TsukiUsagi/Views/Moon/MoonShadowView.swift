import SwiftUI

struct MoonShadowView: View {
    @State private var animate = false
    let duration: Double
    let nearY: CGFloat
    let farY: CGFloat

    init(duration: Double = 2.0, nearY: CGFloat = 10, farY: CGFloat = 30) {
        self.duration = duration
        self.nearY = nearY
        self.farY = farY
    }

    var body: some View {
        Circle()
            .fill(Color(hex: "#660066").opacity(0.9))
            .frame(width: 200, height: 200)
            .offset(y: animate ? nearY : farY)
            .blur(radius: 4)
            .onAppear {
                withAnimation(
                    Animation
                        .timingCurve(0.4, 0, 0.8, 1.0, duration: duration)
                        .repeatForever(autoreverses: true)
                ) {
                    animate.toggle()
                }
            }
    }
}

#Preview {
    MoonShadowView()
}