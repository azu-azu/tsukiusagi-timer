import SwiftUI

struct TimerTextView: View {
    let timeText: String
    let isSessionFinished: Bool

    var body: some View {
        Text(timeText)
            .font(DesignTokens.Fonts.timerDisplay)
            .opacity(isSessionFinished ? 0 : 1.0)
            .transition(.opacity)
            // .foregroundColor(.white) を削除 - StartPulseAnimationModifierで制御するため
            // .scaleEffect(1.0, anchor: .center) を削除 - StartPulseAnimationModifierで制御するため
    }
}
