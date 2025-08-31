import SwiftUI

struct DayCircleView: View {
    let dayIndex: Int
    let isUsed: Bool
    let weekdayText: String

    private var isToday: Bool {
        Date().dayOfWeek == dayIndex
    }

    private var isFutureDay: Bool {
        Date().dateForDayOfWeek(dayIndex) > Date()
    }

    var body: some View {
        Circle()
            .fill(isToday ? DesignTokens.BlackColors.primary : circleColor)
            .frame(width: 32, height: 32)
            .overlay(
                Text(weekdayText)
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(isToday ? DesignTokens.PureColors.textWhite : (isUsed ? DesignTokens.PureColors.textWhite : DesignTokens.MoonColors.textSecondary))
            )
            .overlay(alignment: .bottom) {
                if isToday && !isUsed && !isFutureDay {
                    Circle()
                        .fill(Color(hex: "0A84FF"))
                        .frame(width: 6, height: 6)
                        .offset(y: 9)
                }
            }
            .scaleEffect(isToday ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isToday)
    }

    private var circleColor: Color {
        if isUsed {
            return Color(hex: "0A84FF")
        } else if isFutureDay {
            return DesignTokens.MoonColors.surfaceSecondary
        } else {
            return DesignTokens.MoonColors.surfaceTertiary
        }
    }
}
