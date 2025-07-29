import SwiftUI

struct WeeklyCalendarSectionView: View {
    @ObservedObject var streakManager: StreakManager
    let weekdays: [String]

    var body: some View {
        VStack(spacing: 12) {
            // Day circles
            HStack(spacing: 0) {
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

        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignTokens.CosmosColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.pink.opacity(0.2), lineWidth: 1)
                )
        )

        // .background(DesignTokens.CosmosColors.cardBackground) // カード風背景
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4) // やわらか影
    }
}
