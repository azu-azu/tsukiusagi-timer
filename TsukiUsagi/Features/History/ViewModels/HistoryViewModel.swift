import Combine
import Foundation
import SwiftUI

struct SessionRecord: Codable, Identifiable {
    var id: String // UUID から String に変更（固定値）
    var start, end: Date
    var phase: PomodoroPhase
    var activity: String // 上位
    var subtitle: String? // 下位
    var memo: String? // ←★ new

    // 履歴行のduration（秒）
    var duration: TimeInterval { end.timeIntervalSince(start) }
}

// MARK: - Add Session Parameters
struct AddSessionParameters {
    let start: Date
    let end: Date
    let phase: PomodoroPhase
    let activity: String
    let subtitle: String?
    let memo: String?
}

// MARK: - Supporting Types
// MonthSummary は別ファイルで定義済み

@MainActor
class HistoryViewModel: ObservableObject {
    @Published private(set) var history: [SessionRecord] = []

    // ✅ カレンダー機能用の新規追加
    @Published private(set) var fixedDate: Date?
    @Published var selectedDate: Date = Date()

    private let store = HistoryStore() // 下で定義

    init() { history = store.load() } // 起動時に読込

    func add(parameters: AddSessionParameters) {
        guard parameters.phase == .focus else { return } // ← 休憩は記録しない

        // 3秒未満は記録しない！
        // >= 3秒	誤タップではなく意図的操作とみなす最小限
        // >= 60秒	本気の集中だけに絞りたいならこっち（後で調整）
        let duration = parameters.end.timeIntervalSince(parameters.start)
        guard duration >= 3 else { return }

        let record = SessionRecord(
            id: generateFixedId(from: parameters.start), // 固定値IDを生成
            start: parameters.start,
            end: parameters.end,
            phase: parameters.phase,
            activity: parameters.activity,
            subtitle: parameters.subtitle,
            memo: parameters.memo
        )

        history.append(record)
        saveHistory()
    }

    // MARK: - isDeleted判定

    func isDeleted(sessionManager: SessionManager, activity: String) -> Bool {
        !sessionManager.allEntries.contains(where: { $0.sessionName == activity })
    }

    // (Deleted)表記付きアクティビティ名
    func displayActivity(sessionManager: SessionManager, activity: String) -> String {
        isDeleted(sessionManager: sessionManager, activity: activity) ? "\(activity) (Deleted)" : activity
    }

    // 復元処理
    func restore(record: SessionRecord, sessionManager: SessionManager) throws {
        try sessionManager.addOrUpdateEntry(
            originalKey: "",
            sessionName: record.activity,
            descriptions: record.subtitle != nil ? [record.subtitle!] : []
        )
        // 復元後、ViewでisDeletedを再判定すること
    }

    // MARK: - Calendar Support Methods (新規追加)

    func setCalendarFixedDate(_ date: Date) {
        fixedDate = Calendar.current.startOfDay(for: date)
    }

    func clearCalendarFixedDate() {
        fixedDate = nil
    }

    /// 指定月の全日についてDailyHistoryを取得
    func getCalendarDailyHistories(for month: Date) -> [Date: DailyHistory] {
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

            if let dailyHistory = getCalendarDailyHistory(for: date) {
                results[date] = dailyHistory
            }
        }

        return results
    }

    /// 指定日のDailyHistoryを取得
    func getCalendarDailyHistory(for date: Date) -> DailyHistory? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        let daySessions = history.filter { record in
            calendar.isDate(record.start, inSameDayAs: startOfDay)
        }

        let totalMinutes = daySessions.reduce(0) { total, record in
            total + calendarDurationMinutes(record)
        }

        let activities = Dictionary(grouping: daySessions) { record in
            record.activity // 既存のactivityプロパティを直接使用
        }.mapValues { sessions in
            sessions.reduce(0) { total, record in
                total + calendarDurationMinutes(record)
            }
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
    func getCalendarMonthSummary(for month: Date) -> MonthSummary {
        let dailyHistories = getCalendarDailyHistories(for: month)
        let values = Array(dailyHistories.values)

        let totalMinutes = values.reduce(0) { $0 + $1.totalMinutes }
        let totalSessions = values.reduce(0) { $0 + $1.sessionCount }
        let activeDays = values.filter { $0.hasRecords }.count

        // 全アクティビティを集計
        var allActivities: [String: Int] = [:]
        for daily in values {
            for (activity, minutes) in daily.activities {
                allActivities[activity, default: 0] += minutes
            }
        }

        return MonthSummary(
            month: month,
            totalMinutes: totalMinutes,
            totalSessions: totalSessions,
            activeDays: activeDays,
            topActivities: allActivities.sorted { $0.value > $1.value }.prefix(5).map(\.key)
        )
    }

    // MARK: - Calendar Private Helpers (新規追加)

    /// SessionRecordの時間を分に変換（カレンダー用）
    private func calendarDurationMinutes(_ record: SessionRecord) -> Int {
        let seconds = record.duration // 既存のdurationプロパティを使用
        return max(Int(seconds) / 60, 1)
    }

    // MARK: - Helper Methods (既存)

    /// 固定値のIDを生成（日時ベース）
    private func generateFixedId(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    // MARK: - Memo Operations

    /// 指定されたレコードのmemoを更新
    func updateMemo(for recordId: String, newMemo: String?) {
        guard let index = history.firstIndex(where: { $0.id == recordId }) else {
            return
        }

        history[index].memo = newMemo?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil : newMemo
        saveHistory()
    }

    /// 指定されたレコードを取得
    func getRecord(by id: String) -> SessionRecord? {
        return history.first { $0.id == id }
    }

    // MARK: - Save Operations

    /// 履歴データの永続化（共通処理）
    private func saveHistory() {
        store.save(history)
    }

    /// 外部API用の保存メソッド（後方互換性）
    func save() {
        saveHistory()
    }

    func updateLast(activity: String,
                    subtitle: String,
                    memo: String,
                    end: Date? = nil) {
        guard let i = history.indices.last else { return }
        history[i].activity = activity
        history[i].subtitle = subtitle
        history[i].memo = memo
        if let end = end {
            history[i].end = end
        }
        saveHistory()
    }
}
