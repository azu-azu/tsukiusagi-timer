import Foundation

extension HistoryViewModel {
    // MARK: - Fixed Date Support
    // ❌ extensionではstored propertyは使えない
    // @Published private(set) var fixedDate: Date?

    // ✅ 既存のHistoryViewModelクラス内にfixedDateプロパティを追加する必要があります

    func setFixedDate(_ date: Date) {
        // このメソッドは既存のHistoryViewModelクラス内のfixedDateプロパティを使用
        // fixedDate = Calendar.current.startOfDay(for: date)
    }

    func clearFixedDate() {
        // このメソッドは既存のHistoryViewModelクラス内のfixedDateプロパティを使用
        // fixedDate = nil
    }

    // MARK: - Calendar Data Methods

    /// 指定月の全日についてDailyHistoryを取得
    func getDailyHistories(for month: Date) -> [Date: DailyHistory] {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let range = calendar.range(of: .day, in: .month, for: month) else {
            return [:]
        }

        var results: [Date: DailyHistory] = [:]

        for day in range {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) else {
                continue
            }

            if let dailyHistory = getDailyHistory(for: date) {
                results[date] = dailyHistory
            }
        }

        return results
    }

    /// 指定日のDailyHistoryを取得
    func getDailyHistory(for date: Date) -> DailyHistory? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        let daySessions = history.filter { record in
            calendar.isDate(record.start, inSameDayAs: startOfDay)
        }

        let totalSeconds = daySessions.reduce(0) { total, record in
            total + durationSeconds(record)
        }
        let totalMinutes = (totalSeconds + 59) / 60  // 表示用に切り上げ

        // ✅ sessionManagerパラメータを削除して、直接activityを使用
        let activities = Dictionary(grouping: daySessions) { record in
            // 既存のHistoryViewModelのdisplayActivityメソッドを使わず、
            // record.sessionNameを直接使用するか、簡易版を作成
            String(describing: record.sessionName)
        }.mapValues { sessions in
            let seconds = sessions.reduce(0) { total, record in
                total + durationSeconds(record)
            }
            return (seconds + 59) / 60  // 表示用に切り上げ
        }

        return DailyHistory(
            date: startOfDay,
            totalMinutes: totalMinutes,
            sessionCount: daySessions.count,
            activities: activities,
            hasRecords: !daySessions.isEmpty
        )
    }

    /// 月間サマリーを取得
    func getMonthSummary(for month: Date) -> MonthSummary {
        let dailyHistories = getDailyHistories(for: month)
        let values = Array(dailyHistories.values)

        let totalMinutes = values.reduce(0) { $0 + $1.totalMinutes }
        let totalSessions = values.reduce(0) { $0 + $1.sessionCount }
        let activeDays = values.filter { $0.hasRecords }.count

        // 全アクティビティを集計
        var allSessions: [String: Int] = [:]
        for daily in values {
            for (sessionName, minutes) in daily.activities {
                allSessions[sessionName, default: 0] += minutes
            }
        }

        return MonthSummary(
            month: month,
            totalMinutes: totalMinutes,
            totalSessions: totalSessions,
            activeDays: activeDays,
            topActivities: allSessions.sorted { $0.value > $1.value }.prefix(5).map(\.key)
        )
    }

    // MARK: - Private Helpers

    private func durationSeconds(_ record: SessionRecord) -> Int {
        return Int(record.end.timeIntervalSince(record.start))
    }
}

// MARK: - Supporting Types

struct MonthSummary {
    let month: Date
    let totalMinutes: Int
    let totalSessions: Int
    let activeDays: Int
    let topActivities: [String]

    var averageMinutesPerDay: Double {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return 0 }
        return Double(totalMinutes) / Double(range.count)
    }

    var averageMinutesPerActiveDay: Double {
        guard activeDays > 0 else { return 0 }
        return Double(totalMinutes) / Double(activeDays)
    }
}
