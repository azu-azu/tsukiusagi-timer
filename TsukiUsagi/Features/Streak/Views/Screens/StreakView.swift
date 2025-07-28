import SwiftUI

struct StreakView: View {
    @StateObject private var streakManager = StreakManager()

    private let weekdays = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    var body: some View {
        VStack(spacing: 16) {
            // Level Display
            LevelView(level: streakManager.currentLevel)

            // Total Streak Display
            TotalStreakSectionView(streakManager: streakManager)

            // Weekly Usage
            WeeklyUsageSectionView(streakManager: streakManager)

            // Weekly Calendar
            WeeklyCalendarSectionView(streakManager: streakManager)

            // Achievements
            AchievementsSectionView(streakManager: streakManager)

            // Smart Notifications Toggle
            SmartNotificationToggleView(streakManager: streakManager)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .onAppear {
            streakManager.checkWeekTransition()
        }
    }

    // MARK: - View Components

    private func dayCircle(for dayIndex: Int) -> some View {
        let isUsed = streakManager.streakData.currentWeek.usedDays.contains(dayIndex)
        let isToday = Date().dayOfWeek == dayIndex
        let dayDate = Date().dateForDayOfWeek(dayIndex)
        let isFutureDay = dayDate > Date()

        return Circle()
            .fill(circleColor(isUsed: isUsed, isToday: isToday, isFutureDay: isFutureDay))
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

    private func circleColor(isUsed: Bool, isToday: Bool, isFutureDay: Bool) -> Color {
        if isUsed {
            return .pink
        } else if isFutureDay {
            return Color.gray.opacity(0.1)
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}

// MARK: - Standalone Streak Card

struct StreakCardView: View {
    @StateObject private var streakManager = StreakManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🔥 \(streakManager.streakData.totalContinuousStreak)")
                    .font(DesignTokens.Fonts.title)
                    .foregroundColor(.pink)

                Spacer()

                Text("streak")
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
            }

            HStack {
                Text("This week: \(streakManager.streakData.currentWeek.weeklyUsageCount)/7")
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)

                Spacer()
            }
        }
        .padding()
        .background(DesignTokens.CosmosColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .onAppear {
            streakManager.checkWeekTransition()
        }
    }
}

// MARK: - Integration Helper

extension StreakManager {
    /// Call this method when a timer session completes
    func recordTimerUsage() {
        markTodayAsUsed()
    }
}

// MARK: - Preview

#if DEBUG
struct StreakView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            StreakView()
            StreakCardView()
        }
        .padding()
        .background(DesignTokens.CosmosColors.background)
        .previewDisplayName("Streak Views")
    }
}
#endif
