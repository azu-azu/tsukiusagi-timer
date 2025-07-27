import Foundation

struct DailyHistory {
    let date: Date
    let totalMinutes: Int
    let sessionCount: Int
    let activities: [String: Int]    // アクティビティ名: 時間(分)
    let hasRecords: Bool

    // Computed Properties で派生データを生成
    var topActivities: [String] {
        activities
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map(\.key)
    }

    var activityIntensity: ActivityIntensity {
        ActivityIntensity(totalMinutes: totalMinutes)
    }

    var primaryActivity: String? {
        activities.max(by: { $0.value < $1.value })?.key
    }

    // 初期化
    init(date: Date, totalMinutes: Int, sessionCount: Int, activities: [String: Int], hasRecords: Bool) {
        self.date = Calendar.current.startOfDay(for: date)
        self.totalMinutes = totalMinutes
        self.sessionCount = sessionCount
        self.activities = activities
        self.hasRecords = hasRecords
    }
}

// MARK: - Codable Support
extension DailyHistory: Codable, Equatable {
    static func == (lhs: DailyHistory, rhs: DailyHistory) -> Bool {
        return lhs.date == rhs.date &&
               lhs.totalMinutes == rhs.totalMinutes &&
               lhs.sessionCount == rhs.sessionCount &&
               lhs.activities == rhs.activities
    }
}
