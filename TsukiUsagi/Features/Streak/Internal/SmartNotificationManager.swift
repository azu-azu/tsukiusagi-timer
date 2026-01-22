import Foundation
import UserNotifications

// MARK: - Usage Pattern Analysis

struct UsagePattern {
    let preferredTimeSlots: [DateComponents] // sorted by frequency
    let weekdayConsistency: Double  // 0.0 to 1.0
    let weekendConsistency: Double  // 0.0 to 1.0
    let averageStreakLength: Int
    let totalUsageDays: Int
    let isNewUser: Bool

    init(
        preferredTimeSlots: [DateComponents] = [],
        weekdayConsistency: Double = 0.0,
        weekendConsistency: Double = 0.0,
        averageStreakLength: Int = 0,
        totalUsageDays: Int = 0,
        isNewUser: Bool = true
    ) {
        self.preferredTimeSlots = preferredTimeSlots
        self.weekdayConsistency = weekdayConsistency
        self.weekendConsistency = weekendConsistency
        self.averageStreakLength = averageStreakLength
        self.totalUsageDays = totalUsageDays
        self.isNewUser = isNewUser
    }
}

struct TimeSlot {
    let hour: Int
    let frequency: Int

    var dateComponents: DateComponents {
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        return components
    }
}

// MARK: - Smart Notification Manager

class SmartNotificationManager: ObservableObject {
    static let shared = SmartNotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let userDefaults = UserDefaults.standard

    // User preference keys
    private let smartNotificationEnabledKey = "smart_notification_enabled"
    private let lastAnalysisDateKey = "last_usage_analysis_date"
    private let cachedPatternKey = "cached_usage_pattern"

    @Published private var _isSmartNotificationEnabled: Bool

    var isSmartNotificationEnabled: Bool {
        get { _isSmartNotificationEnabled }
        set {
            _isSmartNotificationEnabled = newValue
            userDefaults.set(newValue, forKey: smartNotificationEnabledKey)
            if newValue {
                scheduleSmartNotifications()
            } else {
                cancelSmartNotifications()
            }
        }
    }

    private init() {
        self._isSmartNotificationEnabled = userDefaults.bool(forKey: smartNotificationEnabledKey)
    }

    // MARK: - Usage Pattern Analysis

    /// Analyze user's timer usage patterns from historical data
    func analyzeUsagePattern(from streakData: StreakData) -> UsagePattern {
        let totalDays = streakData.totalDaysUsed
        let currentStreak = streakData.totalContinuousStreak

        // For new users (less than 3 days of usage)
        if totalDays < 3 {
            return UsagePattern(isNewUser: true)
        }

        // Analyze current week usage for time patterns
        let timeSlots = analyzePreferredTimeSlots(from: streakData)
        let weekdayConsistency = calculateWeekdayConsistency(from: streakData)
        let weekendConsistency = calculateWeekendConsistency(from: streakData)

        return UsagePattern(
            preferredTimeSlots: timeSlots.map { $0.dateComponents },
            weekdayConsistency: weekdayConsistency,
            weekendConsistency: weekendConsistency,
            averageStreakLength: currentStreak,
            totalUsageDays: totalDays,
            isNewUser: false
        )
    }

    private func analyzePreferredTimeSlots(from streakData: StreakData) -> [TimeSlot] {
        // For this phase, we'll use a simplified approach
        // In a real implementation, we'd store historical usage times

        // Default preferred time slots based on common usage patterns
        let commonSlots = [
            TimeSlot(hour: 9, frequency: 3),   // Morning routine
            TimeSlot(hour: 14, frequency: 2),  // Afternoon focus
            TimeSlot(hour: 20, frequency: 5),  // Evening most common
            TimeSlot(hour: 22, frequency: 1)   // Late evening
        ]
        return commonSlots.sorted { $0.frequency > $1.frequency }
    }

    private func calculateWeekdayConsistency(from streakData: StreakData) -> Double {
        let currentWeek = streakData.currentWeek
        let weekdayUsage = currentWeek.usedDays.filter { $0 >= 1 && $0 <= 5 } // Mon-Fri
        return Double(weekdayUsage.count) / 5.0
    }

    private func calculateWeekendConsistency(from streakData: StreakData) -> Double {
        let currentWeek = streakData.currentWeek
        let weekendUsage = currentWeek.usedDays.filter { $0 == 0 || $0 == 6 } // Sat-Sun
        return Double(weekendUsage.count) / 2.0
    }

    // MARK: - Notification Content Generation

    /// Generate personalized notification content based on usage pattern
    func generateNotificationMessage(
        for pattern: UsagePattern,
        currentStreak: Int
    ) -> (title: String, body: String) {
        let title: String
        let body: String

        if pattern.isNewUser || pattern.totalUsageDays < 3 {
            title = "🌱 Start Your Focus Journey"
            body = "Let's build your new habit today! Even 5 minutes counts."
        } else if currentStreak == 0 {
            title = "🔄 Time for a Fresh Start"
            body = "Your streak may have paused, but every expert was once a beginner. Let's restart!"
        } else if currentStreak < 5 {
            title = "🔥 Streak Building"
            body = "You've got momentum! Day \(currentStreak) and counting. Keep it up!"
        } else if currentStreak < 10 {
            title = "⚡ Getting Consistent"
            body = "Day \(currentStreak)! You're developing a real habit. Don't break the chain!"
        } else if currentStreak < 30 {
            title = "⭐ Streak Master"
            body = "\(currentStreak) days strong! You're becoming unstoppable. Next achievement awaits!"
        } else if currentStreak < 100 {
            title = "👑 Habit Legend"
            body = "Incredible! \(currentStreak) days of consistency. You're inspiring!"
        } else {
            title = "🎖 Elite Focus Master"
            body = "\(currentStreak) days! You've mastered the art of consistency. Legendary!"
        }
        return (title, body)
    }

    // MARK: - Smart Notification Scheduling

    /// Request notification permissions
    func requestNotificationPermissions() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    /// Schedule smart notifications based on usage pattern
    func scheduleSmartNotifications() {
        guard isSmartNotificationEnabled else { return }

        Task {
            let hasPermission = await requestNotificationPermissions()
            guard hasPermission else { return }

            await MainActor.run {
                scheduleNextReminder()
            }
        }
    }

    private func scheduleNextReminder() {
        // Cancel existing smart notifications
        cancelSmartNotifications()

        // Get optimal time slot (default to 8 PM if no pattern available)
        let reminderHour = getOptimalReminderTime()

        // Schedule notification for tomorrow at optimal time
        scheduleNotification(at: reminderHour)
    }

    private func getOptimalReminderTime() -> Int {
        // For this phase, use a default optimal time
        // In future versions, this would use the analyzed pattern
        return 20 // 8 PM
    }

    private func scheduleNotification(at hour: Int) {
        let content = UNMutableNotificationContent()

        // We'll generate content dynamically when the notification fires
        // For now, use a default message
        content.title = "🔥 Time to Focus"
        content.body = "Your daily focus session is waiting! Keep your streak alive."
        content.sound = .default
        content.badge = 1

        // Schedule for the specified hour
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "smart_daily_reminder",
            content: content,
            trigger: trigger
        )
        notificationCenter.add(request) { _ in }
    }

    /// Update notification content based on current streak and pattern
    func updateNotificationContent(streakData: StreakData) {
        guard isSmartNotificationEnabled else { return }
        let pattern = analyzeUsagePattern(from: streakData)
        let (title, body) = generateNotificationMessage(for: pattern, currentStreak: streakData.totalContinuousStreak)

        // Cancel and reschedule with updated content
        cancelSmartNotifications()

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1

        let reminderHour = getOptimalReminderTime()
        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "smart_daily_reminder",
            content: content,
            trigger: trigger
        )
        notificationCenter.add(request) { _ in }
    }

    /// Cancel all smart notifications
    func cancelSmartNotifications() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["smart_daily_reminder"])
    }

    // MARK: - Public Interface

    /// Enable smart notifications and start scheduling
    func enableSmartNotifications() {
        isSmartNotificationEnabled = true
    }

    /// Disable smart notifications and cancel all scheduled ones
    func disableSmartNotifications() {
        isSmartNotificationEnabled = false
    }

    /// Check if notifications are properly configured
    func checkNotificationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
}
