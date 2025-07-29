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
                            .foregroundColor(DesignTokens.MoonColors.textSecondary)
                    } else if isToday && !isFutureDay {
                        Circle()
                            .stroke(DesignTokens.MoonColors.accentBlue, lineWidth: 2)
                    }
                }
            )
            .scaleEffect(isToday ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isToday)
    }

    private var circleColor: Color {
        if isUsed {
            return DesignTokens.MoonColors.accentBlue
        } else if isFutureDay {
            return DesignTokens.MoonColors.surfaceSecondary
        } else {
            return DesignTokens.MoonColors.surfaceTertiary
        }
    }
}
