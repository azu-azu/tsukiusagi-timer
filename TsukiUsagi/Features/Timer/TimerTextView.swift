import SwiftUI

struct TimerTextView: View {
    let timeText: String
    let isSessionFinished: Bool
    let flashYellow: Bool
    let flashScale: Bool

    var body: some View {
        Text(timeText)
            // swiftlint:disable:next forbidden-font-direct
            .font(.system(size: 65, weight: .bold, design: .rounded)) // [理由] タイマー表示は特大・丸みデザインが要件
            .opacity(isSessionFinished ? 0 : 1.0)
            .transition(.opacity)
            .foregroundColor(flashYellow ? .yellow : .white)
            .scaleEffect(flashScale ? 1.5 : 1.0, anchor: .center)
    }
}