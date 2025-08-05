import SwiftUI

struct WeeklyCalendarSectionView: View {
    @ObservedObject var streakManager: StreakManager

    private let weekdays = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    var body: some View {
        VStack(spacing: 6) {
            Text("Your Weekly Progress")
                .font(DesignTokens.Fonts.labelBold)
                .foregroundColor(DesignTokens.MoonColors.accentBlueStrong)
            
            // Day circles
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    DayCircleView(
                        dayIndex: dayIndex,
                        isUsed: streakManager.streakData.currentWeek.usedDays.contains(dayIndex),
                        weekdayText: weekdays[dayIndex]
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }

        .padding()
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4) // やわらか影

        // カード型を際立たせたい場合
        .background(DesignTokens.CosmosColors.background)
    }
}
