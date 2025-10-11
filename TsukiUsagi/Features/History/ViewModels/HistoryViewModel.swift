import Combine
import Foundation
import SwiftUI

struct SessionRecord: Codable, Identifiable {
    var id: String // UUID から String に変更（固定値）
    var start, end: Date
    var phase: PomodoroPhase
    var sessionName: String // 上位
    var task: String? // 下位
    var memo: String? // ←★ legacy memo
    // 静かな完了（通知を出さず復帰時に確定）
    var completedSilently: Bool?

    // 履歴行のduration（秒）
    var duration: TimeInterval { end.timeIntervalSince(start) }

    private enum CodingKeys: String, CodingKey {
        case id, start, end, phase, memo, completedSilently
        case sessionName = "activity"
        case task
        case legacySubtitle = "subtitle"
    }

    init(
        id: String,
        start: Date,
        end: Date,
        phase: PomodoroPhase,
        sessionName: String,
        task: String?,
        memo: String?,
        completedSilently: Bool? = nil
    ) {
        self.id = id
        self.start = start
        self.end = end
        self.phase = phase
        self.sessionName = sessionName
        self.task = task
        self.memo = memo
        self.completedSilently = completedSilently
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        start = try container.decode(Date.self, forKey: .start)
        end = try container.decode(Date.self, forKey: .end)
        phase = try container.decode(PomodoroPhase.self, forKey: .phase)
        sessionName = try container.decode(String.self, forKey: .sessionName)
        if let decodedTask = try container.decodeIfPresent(String.self, forKey: .task) {
            task = decodedTask
        } else {
            task = try container.decodeIfPresent(String.self, forKey: .legacySubtitle)
        }
        memo = try container.decodeIfPresent(String.self, forKey: .memo)
        completedSilently = try container.decodeIfPresent(Bool.self, forKey: .completedSilently)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(start, forKey: .start)
        try container.encode(end, forKey: .end)
        try container.encode(phase, forKey: .phase)
        try container.encode(sessionName, forKey: .sessionName)
        try container.encode(task, forKey: .task)
        try container.encodeIfPresent(memo, forKey: .memo)
        try container.encodeIfPresent(completedSilently, forKey: .completedSilently)
    }

    // MARK: - Legacy accessors (temporary)

    @available(*, deprecated, message: "Use sessionName instead of activity")
    var activity: String {
        get { sessionName }
        set { sessionName = newValue }
    }

    @available(*, deprecated, message: "Use task instead of subtitle")
    var subtitle: String? {
        get { task }
        set { task = newValue }
    }

    @available(*, deprecated, message: "Use task instead.")
    var description: String? {
        get { task }
        set { task = newValue }
    }

    @available(*, deprecated, message: "Use task-based initializer instead.")
    init(
        id: String,
        start: Date,
        end: Date,
        phase: PomodoroPhase,
        sessionName: String,
        description: String?,
        memo: String?,
        completedSilently: Bool? = nil
    ) {
        self.init(
            id: id,
            start: start,
            end: end,
            phase: phase,
            sessionName: sessionName,
            task: description,
            memo: memo,
            completedSilently: completedSilently
        )
    }
}

// MARK: - Add Session Parameters
struct AddSessionParameters {
    let start: Date
    let end: Date
    let phase: PomodoroPhase
    let sessionName: String
    let task: String?
    let memo: String?
    let completedSilently: Bool
}

// MARK: - Supporting Types
// MonthSummary は別ファイルで定義済み

@MainActor
class HistoryViewModel: ObservableObject {
    @Published private(set) var history: [SessionRecord] = []
    @Published private(set) var reflectionsByDay: [Date: DayReflection] = [:]
    @Published private(set) var isSavingReflections = false
    @Published private(set) var reflectionSaveError: Error?

    // ✅ カレンダー機能用の新規追加
    @Published private(set) var fixedDate: Date?
    @Published var selectedDate: Date = Date()

    private let store: HistoryStore // 下で定義
    private var migrationVersion: Int = 1
    private var saveRetryAttempts: Int = 0
    private var saveRetryWorkItem: DispatchWorkItem?
    private let maxRetryAttempts: Int = 5

    init(store: HistoryStore = HistoryStore()) {
        self.store = store
        let snapshot = store.load()
        history = snapshot.sessions
        reflectionsByDay = snapshot.reflections
        migrationVersion = snapshot.migrationVersion
    } // 起動時に読込

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
            sessionName: parameters.sessionName,
            task: parameters.task,
            memo: parameters.memo,
            completedSilently: parameters.completedSilently
        )

        history.append(record)
        saveHistory()
    }

    // MARK: - isDeleted判定

    func isDeleted(sessionManager: SessionManager, sessionName: String) -> Bool {
        !sessionManager.allEntries.contains(where: { $0.sessionName == sessionName })
    }

    // (Deleted)表記付きアクティビティ名
    func displaySessionName(sessionManager: SessionManager, sessionName: String) -> String {
        isDeleted(sessionManager: sessionManager, sessionName: sessionName) ? "\(sessionName) (Deleted)" : sessionName
    }

    @available(*, deprecated, message: "Use isDeleted(sessionManager:sessionName:) instead")
    func isDeleted(sessionManager: SessionManager, activity: String) -> Bool {
        isDeleted(sessionManager: sessionManager, sessionName: activity)
    }

    @available(*, deprecated, message: "Use displaySessionName(sessionManager:sessionName:) instead")
    func displayActivity(sessionManager: SessionManager, activity: String) -> String {
        displaySessionName(sessionManager: sessionManager, sessionName: activity)
    }

    // 復元処理
    func restore(record: SessionRecord, sessionManager: SessionManager) throws {
        try sessionManager.addOrUpdateEntry(
            originalKey: "",
            sessionName: record.sessionName,
            tasks: record.task != nil ? [record.task!] : []
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
            record.sessionName
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
            for (sessionName, minutes) in daily.activities {
                allActivities[sessionName, default: 0] += minutes
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

    /// 新しいレコードを追加
    func addRecord(_ record: SessionRecord) {
        history.append(record)
        saveHistory()
    }

    // MARK: - Reflection Operations

    func reflectionText(for date: Date) -> String {
        reflectionsByDay[HistoryDateKey.dayKey(for: date)]?.text ?? ""
    }

    func reflection(for date: Date) -> DayReflection? {
        reflectionsByDay[HistoryDateKey.dayKey(for: date)]
    }

    func updateReflection(for date: Date, text: String) {
        let key = HistoryDateKey.dayKey(for: date)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            if reflectionsByDay.removeValue(forKey: key) != nil {
                isSavingReflections = true
                saveHistory()
            }
            return
        }

        var reflection = reflectionsByDay[key] ?? DayReflection(
            date: key,
            text: "",
            lastUpdatedAt: Date(),
            isPendingSave: false
        )

        if reflection.text == trimmed {
            return
        }

        reflection.text = trimmed
        reflection.lastUpdatedAt = Date()
        reflection.isPendingSave = true
        reflectionsByDay[key] = reflection
        isSavingReflections = true
        saveHistory()
    }

    func retrySaveReflection() {
        reflectionSaveError = nil
        retryPendingSave()
    }

    // MARK: - Save Operations

    /// 履歴データの永続化（共通処理）: 楽観的UI + 失敗時に指数バックオフで自動リトライ
    private func saveHistory() {
        // 進行中のリトライがあればキャンセルして最新スナップショットを使う
        saveRetryWorkItem?.cancel()
        let snapshotReflections = reflectionsByDay
        let snapshot = HistorySnapshot(
            migrationVersion: max(migrationVersion, 1),
            sessions: history,
            reflections: snapshotReflections
        )
        store.save(snapshot) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                Task { @MainActor in
                    self.saveRetryAttempts = 0
                    self.migrationVersion = max(self.migrationVersion, 1)
                    self.markReflectionsAsSaved(snapshotReflections)
                    self.isSavingReflections = self.reflectionsByDay.values.contains { $0.isPendingSave }
                    self.reflectionSaveError = nil
                }
            case .failure(let error):
                Task { @MainActor in
                    self.reflectionSaveError = error
                    NotificationCenter.default.post(name: Notification.Name("HistorySaveFailed"), object: error)
                    self.scheduleHistorySaveRetry()
                    self.isSavingReflections = self.reflectionsByDay.values.contains { $0.isPendingSave }
                }
            }
        }
    }

    /// 外部API用の保存メソッド（後方互換性）
    func save() {
        saveHistory()
    }

    func updateLast(sessionName: String,
                    task: String,
                    memo: String,
                    end: Date? = nil) {
        guard let i = history.indices.last else { return }
        history[i].sessionName = sessionName
        history[i].task = task
        history[i].memo = memo
        if let end = end {
            history[i].end = end
        }
        saveHistory()
    }

    @available(*, deprecated, message: "Use updateLast(sessionName:task:memo:end:) instead.")
    func updateLast(sessionName: String,
                    description: String,
                    memo: String,
                    end: Date? = nil) {
        updateLast(sessionName: sessionName, task: description, memo: memo, end: end)
    }

    /// UIのCTAから呼ばれる明示的な再試行
    func retryPendingSave() {
        saveRetryWorkItem?.cancel()
        saveRetryAttempts = 0
        saveHistory()
    }
}

// MARK: - Retry helpers
private extension HistoryViewModel {
    func markReflectionsAsSaved(_ snapshotReflections: [Date: DayReflection]) {
        var updated = reflectionsByDay
        for (date, reflection) in snapshotReflections where reflection.isPendingSave {
            guard let current = updated[date],
                current.lastUpdatedAt == reflection.lastUpdatedAt else {
                continue
            }
            var saved = current
            saved.isPendingSave = false
            updated[date] = saved
        }
        reflectionsByDay = updated
    }

    func scheduleHistorySaveRetry() {
        guard saveRetryAttempts < maxRetryAttempts else {
            NotificationCenter.default.post(name: Notification.Name("HistorySaveGaveUp"), object: nil)
            return
        }
        saveRetryAttempts += 1
        let delay = min(30.0, pow(2.0, Double(saveRetryAttempts - 1))) // 1,2,4,8,16,30cap
        NotificationCenter.default.post(name: Notification.Name("HistorySaveRetrying"), object: delay)

        let work = DispatchWorkItem { [weak self] in
            self?.saveHistory()
        }
        saveRetryWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

}
