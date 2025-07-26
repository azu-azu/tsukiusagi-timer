import SwiftUI

struct MoonShadow: View {
    @State private var animate = false
    // 🔽 公開プロパティ（全部デフォルト付き）
    var moonSize: CGFloat = 200
    var duration: Double = 2.0
    var nearY: CGFloat = 10
    var farY: CGFloat = 30
    var isAnimationActive: Bool = true

    var body: some View {
        Circle()
            .fill(Color(hex: "#660066").opacity(0.9))
            .frame(width: moonSize, height: moonSize)
            .offset(y: animate ? farY : nearY)
            .blur(radius: 4)
            .onAppear {
                if isAnimationActive {
                    withAnimation(
                        Animation
                            .timingCurve(0.4, 0, 0.8, 1.0, duration: duration)
                            .repeatForever(autoreverses: true)
                    ) {
                        animate = true
                    }
                } else {
                    animate = false
                }
            }
            .onChange(of: isAnimationActive) { _, newValue in
                if newValue {
                    withAnimation(
                        Animation
                            .timingCurve(0.4, 0, 0.8, 1.0, duration: duration)
                            .repeatForever(autoreverses: true)
                    ) {
                        animate = true
                    }
                } else {
                    animate = false
                }
            }
    }
}

#Preview {
    MoonShadow()
}
