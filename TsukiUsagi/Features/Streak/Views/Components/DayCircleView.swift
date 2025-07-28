import SwiftUI

struct DayCircleView: View {
    let dayIndex: Int
    let isUsed: Bool

    private var isToday: Bool {
        Date().dayOfWeek == dayIndex
    }

    private var isFutureDay: Bool {
        Date().dateForDayOfWeek(dayIndex) > Date()
    }

    var body: some View {
        Circle()
            .fill(circleColor)
            .frame(width: 32, height: 32)
            .overlay(
                Group {
                    if isUsed {
                        Text("✓")
                            .font(DesignTokens.Fonts.caption)
                            .foregroundColor(.white)
                    } else if isToday && !isFutureDay {
                        Circle()
                            .stroke(Color.pink, lineWidth: 2)
                    }
                }
            )
            .scaleEffect(isToday ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isToday)
    }

    private var circleColor: Color {
        if isUsed {
            return .pink
        } else if isFutureDay {
            return Color.gray.opacity(0.1)
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}
