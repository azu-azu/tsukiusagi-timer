import SwiftUI

struct WeeklyCalendarSectionView: View {
    @ObservedObject var streakManager: StreakManager

    private let weekdays = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    var body: some View {
        VStack(spacing: 12) {
            // Weekday labels
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    Text(weekdays[dayIndex])
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day circles
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    DayCircleView(
                        dayIndex: dayIndex,
                        isUsed: streakManager.streakData.currentWeek.usedDays.contains(dayIndex)
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}
