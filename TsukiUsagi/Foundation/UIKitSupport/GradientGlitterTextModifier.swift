import SwiftUI

// 使い方
// Text("Gradient Glitter Text")
//     .gradientGlitter()

// Modifier本体
private struct GradientGlitterTextModifier: ViewModifier {
    let font: Font
    let height: CGFloat

    init(font: Font = .system(size: 60, weight: .bold), height: CGFloat = 60) {
        self.font = font
        self.height = height
    }

    func body(content: Content) -> some View {
        content
            .font(font)
            .mask(
                GradientGlitterView()
                    .frame(height: height)
            )
    }
}

// Gradientで動的にキラキラを表現するView
private struct GradientGlitterView: View {
    @State private var move = false

    var body: some View {
        LinearGradient(
            colors: [.yellow, .white, .yellow],
            startPoint: move ? .topLeading : .bottomTrailing,
            endPoint: move ? .bottomTrailing : .topLeading
        )
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: true)) {
                move.toggle()
            }
        }
    }
}

// Text (もしくは View) 用の extension
extension View {
    func gradientGlitter(
        font: Font = .system(size: 60, weight: .bold),
        height: CGFloat = 60
    ) -> some View {
        self.modifier(GradientGlitterTextModifier(font: font, height: height))
    }
}
