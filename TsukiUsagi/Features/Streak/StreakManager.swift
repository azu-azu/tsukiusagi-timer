import Foundation

// MARK: - Data Models

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
    
    init(id: UUID = UUID(), type: AchievementType, title: String, description: String, iconName: String, unlockedAt: Date?) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.iconName = iconName
        self.unlockedAt = unlockedAt
    }
}

struct WeeklyTimerUsage: Codable {
    let weekStartDate: Date
    var usedDays: Set<Int>
    let createdAt: Date
    var lastUpdated: Date

    var weeklyUsageCount: Int {
        usedDays.count
    }

    var weeklyUsageRate: Double {
        Double(usedDays.count) / 7.0
    }

    init(weekStartDate: Date) {
        self.weekStartDate = weekStartDate
        self.usedDays = Set<Int>()
        self.createdAt = Date()
        self.lastUpdated = Date()
    }
    
    init(weekStartDate: Date, usedDays: Set<Int>, createdAt: Date, lastUpdated: Date) {
        self.weekStartDate = weekStartDate
        self.usedDays = usedDays
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
    }
}

struct StreakData: Codable {
    var currentWeek: WeeklyTimerUsage
    var currentWeeklyStreak: Int
    var totalContinuousStreak: Int
    var longestStreak: Int
    var lastUsedDate: Date?
    var totalDaysUsed: Int
    
    // Achievement tracking
    var consecutiveWeeksWithFivePlusDays: Int
    var lastBreakDate: Date?
    
    // XP tracking
    var totalXP: Int
    var lastStreakMilestone: Int

    init(weekStartDate: Date) {
        self.currentWeek = WeeklyTimerUsage(weekStartDate: weekStartDate)
        self.currentWeeklyStreak = 0
        self.totalContinuousStreak = 0
        self.longestStreak = 0
        self.lastUsedDate = nil
        self.totalDaysUsed = 0
        self.consecutiveWeeksWithFivePlusDays = 0
        self.lastBreakDate = nil
        self.totalXP = 0
        self.lastStreakMilestone = 0
    }
}

// MARK: - Streak Manager

class StreakManager: ObservableObject {
    @Published var streakData: StreakData
    @Published var achievements: [Achievement] = []
    @Published var currentLevel: UserLevel = UserLevel.calculateLevel(from: 0)

    private let userDefaults = UserDefaults.standard
    private let streakDataKey = "streak_current_data"
    private let achievementsKey = "streak_achievements"
    
    // Smart notification integration
    private let smartNotificationManager = SmartNotificationManager.shared

    init() {
        self.streakData = StreakManager.loadStreakData()
        self.achievements = Self.loadAchievements()
        self.currentLevel = UserLevel.calculateLevel(from: streakData.totalXP)
        checkWeekTransition()
    }

    // MARK: - Public Methods

    /// Mark today as used and update streaks
    func markTodayAsUsed() {
        let today = Date()
        let todayDayOfWeek = today.dayOfWeek

        // Check if we need to transition to a new week
        checkWeekTransition()

        // Don't mark the same day twice
        if streakData.currentWeek.usedDays.contains(todayDayOfWeek) {
            return
        }

        // Mark today as used
        streakData.currentWeek.usedDays.insert(todayDayOfWeek)
        streakData.currentWeek.lastUpdated = today
        streakData.totalDaysUsed += 1

        // Calculate streaks
        calculateStreaks()

        // Update last used date
        streakData.lastUsedDate = today
        
        // Check for new achievements
        checkForNewAchievements()
        
        // Calculate and award XP
        calculateAndAwardXP()
        
        // Update smart notifications with new streak data
        updateSmartNotifications()

        // Save changes
        saveIfChanged()

        print("📅 Streak Manager: Marked today as used. Total streak: \(streakData.totalContinuousStreak)")
    }

    /// Calculate current and total streaks
    func calculateStreaks() {
        calculateWeeklyStreak()
        calculateTotalContinuousStreak()
        updateLongestStreak()
    }

    /// Check if we need to transition to a new week and handle it
    func checkWeekTransition() {
        let today = Date()
        let currentWeekStart = today.startOfWeek

        if !Calendar.current.isDate(streakData.currentWeek.weekStartDate, inSameDayAs: currentWeekStart) {
            // We've transitioned to a new week
            let oldWeekData = streakData.currentWeek

            // Track consecutive weeks with 5+ days for consistency achievement
            if oldWeekData.weeklyUsageCount >= 5 {
                streakData.consecutiveWeeksWithFivePlusDays += 1
                // Award weekly completion XP
                awardXP(for: [.weeklyCompletion])
            } else {
                streakData.consecutiveWeeksWithFivePlusDays = 0
            }

            // Create new week
            streakData.currentWeek = WeeklyTimerUsage(weekStartDate: currentWeekStart)

            // Check if streak continues from last week
            if let lastUsedDate = streakData.lastUsedDate {
                let daysSinceLastUse = Calendar.current.dateComponents([.day], from: lastUsedDate, to: today).day ?? 0

                // If more than 1 day has passed, reset the streak
                if daysSinceLastUse > 1 {
                    streakData.lastBreakDate = lastUsedDate // Record when the break started
                    streakData.totalContinuousStreak = 0
                    streakData.currentWeeklyStreak = 0
                    streakData.consecutiveWeeksWithFivePlusDays = 0 // Reset consistency tracking
                    print("📅 Streak Manager: Streak broken due to gap. Days since last use: \(daysSinceLastUse)")
                } else {
                    // Streak continues, reset weekly streak counter
                    streakData.currentWeeklyStreak = 0
                    print("📅 Streak Manager: Week transition, streak continues: \(streakData.totalContinuousStreak)")
                }
            }

            saveIfChanged()
        }
    }

    /// Save streak data if it has changed
    func saveIfChanged() {
        save()
    }

    // MARK: - Private Methods

    private func calculateWeeklyStreak() {
        // Count consecutive days from the beginning of the week
        var consecutiveDays = 0

        // Check days in order from Sunday (0) to Saturday (6)
        for day in 0...6 {
            if streakData.currentWeek.usedDays.contains(day) {
                consecutiveDays += 1
            } else {
                // Stop counting if we hit a gap, unless it's a future day
                let today = Date()
                let dayDate = today.dateForDayOfWeek(day)

                // If this day hasn't happened yet, don't break the streak
                if dayDate > today {
                    break
                } else {
                    // This is a past day that wasn't used, so streak ends here
                    break
                }
            }
        }

        streakData.currentWeeklyStreak = consecutiveDays
    }

    private func calculateTotalContinuousStreak() {
        guard let lastUsedDate = streakData.lastUsedDate else {
            streakData.totalContinuousStreak = 0
            return
        }

        let today = Date()

        // If today is already marked, include it in the count
        if today.isSameDay(as: lastUsedDate) {
            // Count all consecutive days leading up to today
            streakData.totalContinuousStreak = countConsecutiveDaysEndingToday()
        } else {
            // Check if streak is broken
            let daysSinceLastUse = Calendar.current.dateComponents([.day], from: lastUsedDate, to: today).day ?? 0

            if daysSinceLastUse > 1 {
                // Streak is broken
                streakData.totalContinuousStreak = 0
            }
            // If daysSinceLastUse == 1, we maintain the existing streak count
        }
    }

    private func countConsecutiveDaysEndingToday() -> Int {
        let today = Date()
        var count = 0
        var currentDate = today

        // Count backwards from today
        while true {
            let dayOfWeek = currentDate.dayOfWeek
            let weekStart = currentDate.startOfWeek

            // If this is the current week, check usedDays
            if Calendar.current.isDate(weekStart, inSameDayAs: streakData.currentWeek.weekStartDate) {
                if streakData.currentWeek.usedDays.contains(dayOfWeek) {
                    count += 1
                } else {
                    break
                }
            } else {
                // For previous weeks, we would need to store historical data
                // For Phase 1, we'll only count the current week's consecutive days
                break
            }

            // Move to previous day
            guard let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }

        return count
    }

    private func updateLongestStreak() {
        if streakData.totalContinuousStreak > streakData.longestStreak {
            streakData.longestStreak = streakData.totalContinuousStreak
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(streakData)
            userDefaults.set(data, forKey: streakDataKey)
            print("📅 Streak Manager: Data saved successfully")
        } catch {
            print("📅 Streak Manager: Failed to save data - \(error)")
        }
    }

    private static func loadStreakData() -> StreakData {
        let userDefaults = UserDefaults.standard
        let streakDataKey = "streak_current_data"

        guard let data = userDefaults.data(forKey: streakDataKey) else {
            // No existing data, create new
            let today = Date()
            let newData = StreakData(weekStartDate: today.startOfWeek)
            print("📅 Streak Manager: Created new streak data")
            return newData
        }

        do {
            let streakData = try JSONDecoder().decode(StreakData.self, from: data)
            print("📅 Streak Manager: Loaded existing streak data - Total streak: \(streakData.totalContinuousStreak)")
            return streakData
        } catch {
            // Failed to decode, create new
            print("📅 Streak Manager: Failed to decode data, creating new - \(error)")
            let today = Date()
            return StreakData(weekStartDate: today.startOfWeek)
        }
    }
    
    // MARK: - XP System
    
    /// Calculate and award XP for current session
    private func calculateAndAwardXP() {
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
        awardXP(for: xpActions)
        
        // Check for level up
        let newLevel = UserLevel.calculateLevel(from: streakData.totalXP)
        if newLevel.level > oldLevel {
            print("🎉 Level Up! You are now Level \\(newLevel.level) - \\(newLevel.title)")
        }
        currentLevel = newLevel
    }
    
    /// Award XP for specific actions
    private func awardXP(for actions: [XPAction]) {
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
    
    private func getXPActionDescription(_ action: XPAction) -> String {
        switch action {
        case .dailyUsage:
            return "Daily timer usage"
        case .weeklyCompletion:
            return "Weekly completion"
        case .streakMilestone(let days):
            return "\\(days)-day streak milestone"
        case .perfectWeek:
            return "Perfect week (7 days)"
        case .comeback(let gapDays):
            return "Comeback after \\(gapDays) day break"
        }
    }
    
    // MARK: - Achievement System
    
    /// Check for new achievements and unlock them
    func checkForNewAchievements() {
        let today = Date()
        var newlyUnlocked: [Achievement] = []
        
        // Check each achievement type
        for achievementType in Achievement.AchievementType.allCases {
            if !isAchievementUnlocked(achievementType) && shouldUnlockAchievement(achievementType) {
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
            saveAchievements()
        }
    }
    
    private func isAchievementUnlocked(_ type: Achievement.AchievementType) -> Bool {
        return achievements.first(where: { $0.type == type })?.isUnlocked ?? false
    }
    
    private func shouldUnlockAchievement(_ type: Achievement.AchievementType) -> Bool {
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
    
    private func saveAchievements() {
        do {
            let data = try JSONEncoder().encode(achievements)
            userDefaults.set(data, forKey: achievementsKey)
            print("🏆 Achievements saved successfully")
        } catch {
            print("🏆 Failed to save achievements - \\(error)")
        }
    }
    
    private static func loadAchievements() -> [Achievement] {
        let userDefaults = UserDefaults.standard
        let achievementsKey = "streak_achievements"
        
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
    
    // MARK: - Share Functionality
    
    /// Generate and present share sheet for current streak
    func shareStreak() {
        let message = ShareManager.generateShareMessage(
            streakData: streakData,
            currentLevel: currentLevel,
            achievements: achievements
        )
        
        ShareManager.presentShareSheet(message: message)
    }
    
    // MARK: - Smart Notification Integration
    
    /// Update smart notifications based on current streak data
    private func updateSmartNotifications() {
        smartNotificationManager.updateNotificationContent(streakData: streakData)
    }
    
    /// Enable smart notifications
    func enableSmartNotifications() {
        smartNotificationManager.enableSmartNotifications()
    }
    
    /// Disable smart notifications
    func disableSmartNotifications() {
        smartNotificationManager.disableSmartNotifications()
    }
    
    /// Check if smart notifications are enabled
    var isSmartNotificationEnabled: Bool {
        smartNotificationManager.isSmartNotificationEnabled
    }
    
    /// Get current usage pattern analysis
    func getCurrentUsagePattern() -> UsagePattern {
        return smartNotificationManager.analyzeUsagePattern(from: streakData)
    }
}
