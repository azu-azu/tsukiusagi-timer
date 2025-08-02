import SwiftUI

struct WeeklyCalendarSectionView: View {
    @ObservedObject var streakManager: StreakManager

    private let weekdays = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    var body: some View {
        VStack(spacing: 0) {
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
        // カード型を際立たせたい場合
        // .background(DesignTokens.CosmosColors.cardBackground)

        .padding()
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4) // やわらか影
    }
}
