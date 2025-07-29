import SwiftUI

struct WeeklyUsageSectionView: View {
    @ObservedObject var streakManager: StreakManager

    var body: some View {
        HStack {
            Text("📅")
                .font(DesignTokens.Fonts.sectionTitle)
            Text("This week: \(streakManager.streakData.currentWeek.weeklyUsageCount) days")
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)
            Spacer()
        }
    }
}
