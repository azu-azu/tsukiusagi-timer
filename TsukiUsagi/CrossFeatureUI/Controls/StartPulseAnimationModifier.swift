import SwiftUI
import Combine

/// STARTボタン押下時のアニメーションを管理するViewModifier
struct StartPulseAnimationModifier: ViewModifier {
    let publisher: AnyPublisher<Void, Never>

    @State private var flashYellow = false
    @State private var flashScale = false

    func body(content: Content) -> some View {
        content
            // 仕様: スタート時は一瞬イエローで強調 → 白に戻す
            .foregroundColor(flashYellow ? DesignTokens.PureColors.accentYellow : DesignTokens.PureColors.textWhite)
            .scaleEffect(flashScale ? 1.5 : 1.0, anchor: .center)
            .onReceive(publisher) { _ in
                print("StartPulseAnimationModifier: received pulse signal")
                withAnimation(.easeInOut(duration: 0.4)) {
                    print("StartPulseAnimationModifier: setting flashYellow = true")
                    flashYellow = true
                    flashScale = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 1.8)) {
                        print("StartPulseAnimationModifier: resetting flashYellow = false")
                        flashYellow = false
                        flashScale = false
                    }
                }
            }
    }
}

// MARK: - Convenience Extension
extension View {
    /// STARTボタン押下時のアニメーションを適用
    func startPulseAnimation(publisher: AnyPublisher<Void, Never>) -> some View {
        self.modifier(StartPulseAnimationModifier(publisher: publisher))
    }
}
