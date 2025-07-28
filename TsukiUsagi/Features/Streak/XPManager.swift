import Foundation

// MARK: - XP Data Models

enum XPAction {
    case dailyUsage                // +10
    case weeklyCompletion          // +50
    case streakMilestone(Int)     // +5 per day
    case perfectWeek               // +100
    case comeback(gapDays: Int)   // max(20 - gapDays, 5)

    var xpValue: Int {
        switch self {
        case .dailyUsage:
            return 10
        case .weeklyCompletion:
            return 50
        case .streakMilestone(let days):
            return days * 5
        case .perfectWeek:
            return 100
        case .comeback(let gapDays):
            return max(20 - gapDays, 5)
        }
    }
}

struct UserLevel {
    let level: Int
    let currentXP: Int
    let requiredXP: Int
    let title: String

    var progress: Double {
        Double(currentXP) / Double(requiredXP)
    }

    static func calculateLevel(from totalXP: Int) -> UserLevel {
        let level = Int(sqrt(Double(totalXP) / 100)) + 1
        let currentLevelXP = (level - 1) * (level - 1) * 100
        let nextLevelXP = level * level * 100
        let currentXP = totalXP - currentLevelXP
        let requiredXP = nextLevelXP - currentLevelXP

        return UserLevel(
            level: level,
            currentXP: currentXP,
            requiredXP: requiredXP,
            title: levelTitle(for: level)
        )
    }

    private static func levelTitle(for level: Int) -> String {
        switch level {
        case 1...5: return "Beginner"
        case 6...10: return "Explorer"
        case 11...20: return "Dedicated"
        case 21...35: return "Expert"
        case 36...50: return "Master"
        default: return "Legend"
        }
    }
}

// MARK: - XP Manager

class XPManager {

    /// Calculate and award XP for current session
    static func calculateAndAwardXP(
        for streakData: inout StreakData,
        currentLevel: UserLevel
    ) -> (xpActions: [XPAction], newLevel: UserLevel) {
        var xpActions: [XPAction] = []
        let oldLevel = currentLevel.level

        // Daily usage XP
        xpActions.append(.dailyUsage)

        // Check for perfect week
        if streakData.currentWeek.weeklyUsageCount == 7 {
            xpActions.append(.perfectWeek)
        }

        // Check for streak milestones (every 10 days)
        let currentStreak = streakData.totalContinuousStreak
        let milestoneThreshold = 10
        let currentMilestone = (currentStreak / milestoneThreshold) * milestoneThreshold

        if currentMilestone > streakData.lastStreakMilestone && currentMilestone > 0 {
            xpActions.append(.streakMilestone(currentMilestone))
            streakData.lastStreakMilestone = currentMilestone
        }

        // Check for comeback (if this is the first day after a break)
        if currentStreak == 1, let lastBreak = streakData.lastBreakDate {
            let gapDays = Calendar.current.dateComponents([.day], from: lastBreak, to: Date()).day ?? 0
            if gapDays >= 1 {
                xpActions.append(.comeback(gapDays: gapDays))
            }
        }

        // Award XP and update level
        awardXP(for: xpActions, streakData: &streakData)

        // Check for level up
        let newLevel = UserLevel.calculateLevel(from: streakData.totalXP)
        if newLevel.level > oldLevel {
            print("🎉 Level Up! You are now Level \\(newLevel.level) - \\(newLevel.title)")
        }

        return (xpActions, newLevel)
    }

    /// Award XP for specific actions
    static func awardXP(for actions: [XPAction], streakData: inout StreakData) {
        let totalXP = actions.reduce(0) { $0 + $1.xpValue }
        streakData.totalXP += totalXP

        if totalXP > 0 {
            print("💫 Awarded \\(totalXP) XP! Total: \\(streakData.totalXP)")
        }

        for action in actions {
            let description = getXPActionDescription(action)
            print("  • \\(description): +\\(action.xpValue) XP")
        }
    }

    /// Award XP for weekly completion
    static func awardWeeklyCompletionXP(streakData: inout StreakData) {
        awardXP(for: [.weeklyCompletion], streakData: &streakData)
    }

    private static func getXPActionDescription(_ action: XPAction) -> String {
        switch action {
        case .dailyUsage:
            return "Daily timer usage"
        case .weeklyCompletion:
            return "Weekly completion"
        case .streakMilestone:
            return "Streak milestone"
        case .perfectWeek:
            return "Perfect week (7 days)"
        case .comeback:
            return "Comeback bonus"
        }
    }
}

