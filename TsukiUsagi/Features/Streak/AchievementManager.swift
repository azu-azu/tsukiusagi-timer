import Foundation

// MARK: - Achievement Data Models

struct Achievement: Codable, Identifiable {
    let id: UUID
    let type: AchievementType
    let title: String
    let description: String
    let iconName: String
    let unlockedAt: Date?

    var isUnlocked: Bool {
        unlockedAt != nil
    }

    enum AchievementType: String, Codable, CaseIterable {
        case firstDay = "first_day"
        case weekWarrior = "week_warrior"
        case consistency = "consistency"
        case centurion = "centurion"
        case phoenix = "phoenix"

        var defaultAchievement: Achievement {
            switch self {
            case .firstDay:
                return Achievement(
                    id: UUID(),
                    type: .firstDay,
                    title: "First Timer",
                    description: "Complete your first timer session",
                    iconName: "🎯",
                    unlockedAt: nil
                )
            case .weekWarrior:
                return Achievement(
                    id: UUID(),
                    type: .weekWarrior,
                    title: "Week Warrior",
                    description: "Use the timer all 7 days in a week",
                    iconName: "🗓️",
                    unlockedAt: nil
                )
            case .consistency:
                return Achievement(
                    id: UUID(),
                    type: .consistency,
                    title: "Consistency Master",
                    description: "Use the timer 5+ days for 4 weeks in a row",
                    iconName: "📈",
                    unlockedAt: nil
                )
            case .centurion:
                return Achievement(
                    id: UUID(),
                    type: .centurion,
                    title: "Centurion",
                    description: "Achieve a 100-day streak",
                    iconName: "💯",
                    unlockedAt: nil
                )
            case .phoenix:
                return Achievement(
                    id: UUID(),
                    type: .phoenix,
                    title: "Phoenix Rising",
                    description: "Come back after a break of 7+ days",
                    iconName: "🔥",
                    unlockedAt: nil
                )
            }
        }
    }

    init(
        id: UUID = UUID(),
        type: AchievementType,
        title: String,
        description: String,
        iconName: String,
        unlockedAt: Date?
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.iconName = iconName
        self.unlockedAt = unlockedAt
    }
}

// MARK: - Achievement Manager

class AchievementManager {
    private let userDefaults = UserDefaults.standard
    private let achievementsKey = "streak_achievements"
    
    /// Check for new achievements and unlock them
    func checkForNewAchievements(
        streakData: StreakData,
        achievements: inout [Achievement]
    ) -> [Achievement] {
        let today = Date()
        var newlyUnlocked: [Achievement] = []

        // Check each achievement type
        for achievementType in Achievement.AchievementType.allCases {
            if !isAchievementUnlocked(achievementType, in: achievements) && 
               shouldUnlockAchievement(achievementType, streakData: streakData) {
                var newAchievement = achievementType.defaultAchievement
                newAchievement = Achievement(
                    id: newAchievement.id,
                    type: newAchievement.type,
                    title: newAchievement.title,
                    description: newAchievement.description,
                    iconName: newAchievement.iconName,
                    unlockedAt: today
                )

                // Find and update the achievement in the array
                if let index = achievements.firstIndex(where: { $0.type == achievementType }) {
                    achievements[index] = newAchievement
                } else {
                    achievements.append(newAchievement)
                }

                newlyUnlocked.append(newAchievement)
                print("🏆 Achievement Unlocked: \\(newAchievement.title)")
            }
        }

        // Save achievements if any were unlocked
        if !newlyUnlocked.isEmpty {
            saveAchievements(achievements)
        }
        
        return newlyUnlocked
    }

    private func isAchievementUnlocked(_ type: Achievement.AchievementType, in achievements: [Achievement]) -> Bool {
        return achievements.first(where: { $0.type == type })?.isUnlocked ?? false
    }

    private func shouldUnlockAchievement(_ type: Achievement.AchievementType, streakData: StreakData) -> Bool {
        switch type {
        case .firstDay:
            return streakData.totalDaysUsed >= 1

        case .weekWarrior:
            return streakData.currentWeek.weeklyUsageCount == 7

        case .consistency:
            // Check if current week has 5+ days
            if streakData.currentWeek.weeklyUsageCount >= 5 {
                return streakData.consecutiveWeeksWithFivePlusDays >= 4
            }
            return false

        case .centurion:
            return streakData.totalContinuousStreak >= 100

        case .phoenix:
            guard let lastBreak = streakData.lastBreakDate,
                  let lastUsed = streakData.lastUsedDate else { return false }

            let daysBetween = Calendar.current.dateComponents([.day], from: lastBreak, to: lastUsed).day ?? 0
            return daysBetween >= 7 && streakData.totalContinuousStreak > 0
        }
    }

    func saveAchievements(_ achievements: [Achievement]) {
        do {
            let data = try JSONEncoder().encode(achievements)
            userDefaults.set(data, forKey: achievementsKey)
            print("🏆 Achievements saved successfully")
        } catch {
            print("🏆 Failed to save achievements - \\(error)")
        }
    }

    func loadAchievements() -> [Achievement] {
        guard let data = userDefaults.data(forKey: achievementsKey) else {
            // No existing achievements, create default set
            let defaultAchievements = Achievement.AchievementType.allCases.map { $0.defaultAchievement }
            print("🏆 Created default achievement set")
            return defaultAchievements
        }

        do {
            let achievements = try JSONDecoder().decode([Achievement].self, from: data)
            print("🏆 Loaded \\(achievements.count) achievements")
            return achievements
        } catch {
            print("🏆 Failed to decode achievements, creating new - \\(error)")
            return Achievement.AchievementType.allCases.map { $0.defaultAchievement }
        }
    }
}