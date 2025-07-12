import SwiftUI

extension View {
    /// セッション終了時など、一時的なViewの可視性・アクセシビリティ・タッチ制御をまとめて行うmodifier
    func sessionVisibility(isVisible: Bool) -> some View {
        opacity(isVisible ? 1 : 0)
            .accessibility(hidden: !isVisible)
            .allowsHitTesting(isVisible)
    }

    /// セッション終了時のアニメーションを共通化
    func sessionEndTransition(_ timerVM: TimerViewModel) -> some View {
        animation(
            timerVM.shouldSuppressSessionFinishedAnimation
                ? nil
                : .easeInOut(duration: LayoutConstants.sessionEndAnimationDuration),
            value: timerVM.isSessionFinished
        )
    }
}
