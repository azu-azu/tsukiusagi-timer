import SwiftUI

struct TimerTextView: View {
    let timeText: String
    let isSessionFinished: Bool
    let flashYellow: Bool
    let flashScale: Bool

    var body: some View {
        Text(timeText)
            .font(.system(size: 65, weight: .bold, design: .rounded))
            .opacity(isSessionFinished ? 0 : 1.0)
            .transition(.opacity)
            .foregroundColor(flashYellow ? .yellow : .white)
            .scaleEffect(flashScale ? 1.5 : 1.0, anchor: .center)
    }
}