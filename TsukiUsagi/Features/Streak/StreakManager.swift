import Foundation

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

    // Managers
    private let achievementManager = AchievementManager()

    // Smart notification integration
    private let smartNotificationManager = SmartNotificationManager.shared

    init() {
        self.streakData = StreakManager.loadStreakData()
        self.achievements = achievementManager.loadAchievements()
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

        print("📅 Streak Manager: Marked today as used. Total streak: \\(streakData.totalContinuousStreak)")
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
                XPManager.awardWeeklyCompletionXP(streakData: &streakData)
            } else {
                streakData.consecutiveWeeksWithFivePlusDays = 0
            }

            // Create new week
            streakData.currentWeek = WeeklyTimerUsage(weekStartDate: currentWeekStart)

            // Check if streak continues from last week
            if let lastUsedDate = streakData.lastUsedDate {
                let daysSinceLastUse = Calendar.current.dateComponents([.day], from: lastUsedDate, to: today)
                    .day ?? 0

                // If more than 1 day has passed, reset the streak
                if daysSinceLastUse > 1 {
                    streakData.lastBreakDate = lastUsedDate // Record when the break started
                    streakData.totalContinuousStreak = 0
                    streakData.currentWeeklyStreak = 0
                    streakData.consecutiveWeeksWithFivePlusDays = 0 // Reset consistency tracking
                    print("📅 Streak Manager: Streak broken due to gap. Days since last use: \\(daysSinceLastUse)")
                } else {
                    // Streak continues, reset weekly streak counter
                    streakData.currentWeeklyStreak = 0
                    print("📅 Streak Manager: Week transition, streak continues: \\(streakData.totalContinuousStreak)\\n")
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
            print("📅 Streak Manager: Failed to save data - \\(error)")
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
            print("📅 Streak Manager: Loaded existing streak data - Total streak: \\(streakData.totalContinuousStreak)")
            return streakData
        } catch {
            // Failed to decode, create new
            print("📅 Streak Manager: Failed to decode data, creating new - \\(error)")
            let today = Date()
            return StreakData(weekStartDate: today.startOfWeek)
        }
    }

    // MARK: - XP System

    /// Calculate and award XP for current session
    private func calculateAndAwardXP() {
        let result = XPManager.calculateAndAwardXP(for: &streakData, currentLevel: currentLevel)
        currentLevel = result.newLevel
    }

    // MARK: - Achievement System

    /// Check for new achievements and unlock them
    func checkForNewAchievements() {
        _ = achievementManager.checkForNewAchievements(streakData: streakData, achievements: &achievements)
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

// MARK: - Integration Helper

extension StreakManager {
    /// Call this method when a timer session completes
    func recordTimerUsage() {
        markTodayAsUsed()
    }
}
