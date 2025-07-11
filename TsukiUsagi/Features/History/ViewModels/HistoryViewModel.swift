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

@MainActor
class HistoryViewModel: ObservableObject {
    @Published private(set) var history: [SessionRecord] = []
    private let store = HistoryStore() // 下で定義

    init() { history = store.load() } // 起動時に読込

    // 保存
    // TODO: パラメータ数が6個のため、SwiftLint違反。将来的に構造体やラッパー型でまとめて渡す設計にリファクタリングすることを検討。
    func add(start: Date, end: Date,
            phase: PomodoroPhase,
            activity: String,
            subtitle: String?,
            memo: String?) {
        guard phase == .focus else { return } // ← 休憩は記録しない

        // 3秒未満は記録しない！
        // >= 3秒	誤タップではなく意図的操作とみなす最小限
        // >= 60秒	本気の集中だけに絞りたいならこっち（後で調整）
        let duration = end.timeIntervalSince(start)
        guard duration >= 3 else { return }

        let record = SessionRecord(
            id: generateFixedId(from: start), // 固定値IDを生成
            start: start,
            end: end,
            phase: phase,
            activity: activity,
            subtitle: subtitle,
            memo: memo
        )

        history.append(record)
        store.save(history)
    }

    // MARK: - isDeleted判定

    func isDeleted(sessionManager: SessionManager, activity: String) -> Bool {
        !sessionManager.sessions.contains(where: { $0.name == activity })
    }

    // (Deleted)表記付きアクティビティ名
    func displayActivity(sessionManager: SessionManager, activity: String) -> String {
        isDeleted(sessionManager: sessionManager, activity: activity) ? "\(activity) (Deleted)" : activity
    }

    // 復元処理
    func restore(record: SessionRecord, sessionManager: SessionManager) throws {
        let sessionItem = SessionItem(
            id: UUID(),
            name: record.activity,
            subtitle: record.subtitle,
            isFixed: false
        )
        try sessionManager.addSession(sessionItem)
        // 復元後、ViewでisDeletedを再判定すること
    }

    // MARK: - Helper Methods

    /// 固定値のIDを生成（日時ベース）
    private func generateFixedId(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    func save() {
        store.save(history)
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
        save()
    }
}
