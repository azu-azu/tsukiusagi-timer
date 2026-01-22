import Combine
import SwiftUI

// MARK: - Notification Names

extension Notification.Name {
    static let historySaveFailed = Notification.Name("HistorySaveFailed")
    static let historySaveRetrying = Notification.Name("HistorySaveRetrying")
    static let historySaveGaveUp = Notification.Name("HistorySaveGaveUp")
}

@MainActor
class HistoryViewModel: ObservableObject, SessionHistoryServiceable {
    @Published private(set) var history: [SessionRecord] = []
    @Published internal var reflectionsByDay: [Date: DayReflection] = [:]
    @Published internal var isSavingReflections = false
    @Published internal var reflectionSaveError: Error?

    // ✅ カレンダー機能用
    @Published private(set) var fixedDate: Date?
    @Published var selectedDate: Date = Date()

    private let store: HistoryStore
    private var migrationVersion: Int = 1
    private var saveRetryAttempts: Int = 0
    private var saveRetryWorkItem: DispatchWorkItem?
    private let maxRetryAttempts: Int = 5

    /// Short-window dedupe storage for reflection appends
    static var recentReflectionAppends: [Date: String] = [:]

    init(store: HistoryStore = HistoryStore()) {
        self.store = store
        let snapshot = store.load()
        history = snapshot.sessions
        reflectionsByDay = snapshot.reflections
        migrationVersion = snapshot.migrationVersion
    }

    // MARK: - Add Session

    func add(parameters: AddSessionParameters) {
        guard parameters.phase == .focus else { return }

        // 3秒未満は記録しない
        let duration = parameters.end.timeIntervalSince(parameters.start)
        guard duration >= 3 else { return }

        let record = SessionRecord(
            id: generateFixedId(from: parameters.start),
            start: parameters.start,
            end: parameters.end,
            phase: parameters.phase,
            sessionName: parameters.sessionName,
            task: parameters.task,
            memo: parameters.memo,
            completedSilently: parameters.completedSilently
        )

        history.append(record)
        save()
    }

    // MARK: - isDeleted判定

    func isDeleted(sessionManager: SessionManager, sessionName: String) -> Bool {
        !sessionManager.allEntries.contains(where: { $0.sessionName == sessionName })
    }

    func displaySessionName(sessionManager: SessionManager, sessionName: String) -> String {
        let baseName = isDeleted(sessionManager: sessionManager, sessionName: sessionName)
            ? "\(sessionName) (Deleted)"
            : sessionName
        return baseName.withSessionEmoji
    }

    func restore(record: SessionRecord, sessionManager: SessionManager) throws {
        try sessionManager.addOrUpdateEntry(
            originalKey: "",
            sessionName: record.sessionName,
            tasks: record.task != nil ? [record.task!] : []
        )
    }

    // MARK: - Calendar Support

    func setCalendarFixedDate(_ date: Date) {
        fixedDate = Calendar.current.startOfDay(for: date)
    }

    func clearCalendarFixedDate() {
        fixedDate = nil
    }

    // MARK: - Memo Operations

    func updateMemo(for recordId: String, newMemo: String?) {
        guard let index = history.firstIndex(where: { $0.id == recordId }) else {
            return
        }
        let trimmed = newMemo?.trimmingCharacters(in: .whitespacesAndNewlines)
        history[index].memo = trimmed?.isEmpty == true ? nil : newMemo
        save()
    }

    func getRecord(by id: String) -> SessionRecord? {
        return history.first { $0.id == id }
    }

    func addRecord(_ record: SessionRecord) {
        history.append(record)
        save()
    }

    func updateLast(sessionName: String, task: String, memo: String, end: Date? = nil) {
        guard let idx = history.indices.last else { return }
        history[idx].sessionName = sessionName
        history[idx].task = task
        history[idx].memo = memo
        if let end = end {
            history[idx].end = end
        }
        save()
    }

    // MARK: - Save Operations

    func save() {
        saveRetryWorkItem?.cancel()
        let snapshotReflections = reflectionsByDay
        let snapshot = HistorySnapshot(
            migrationVersion: max(migrationVersion, 1),
            sessions: history,
            reflections: snapshotReflections
        )

        do {
            try store.saveSync(snapshot)
            saveRetryAttempts = 0
            migrationVersion = max(migrationVersion, 1)
            markReflectionsAsSaved(snapshotReflections)
            isSavingReflections = reflectionsByDay.values.contains { $0.isPendingSave }
            reflectionSaveError = nil
        } catch {
            #if DEBUG
            print("[history_save_failed] \(error.localizedDescription)")
            #endif
            reflectionSaveError = error
            NotificationCenter.default.post(name: .historySaveFailed, object: error)
            scheduleHistorySaveRetry()
            isSavingReflections = reflectionsByDay.values.contains { $0.isPendingSave }
        }
    }

    func retryPendingSave() {
        saveRetryWorkItem?.cancel()
        saveRetryAttempts = 0
        save()
    }

    // MARK: - Private Helpers

    private func generateFixedId(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    private func scheduleHistorySaveRetry() {
        guard saveRetryAttempts < maxRetryAttempts else {
            NotificationCenter.default.post(name: .historySaveGaveUp, object: nil)
            return
        }
        saveRetryAttempts += 1
        let delay = min(30.0, pow(2.0, Double(saveRetryAttempts - 1)))
        NotificationCenter.default.post(name: .historySaveRetrying, object: delay)

        let work = DispatchWorkItem { [weak self] in
            self?.save()
        }
        saveRetryWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
}
