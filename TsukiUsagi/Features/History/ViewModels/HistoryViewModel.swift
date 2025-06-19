import Foundation
import Combine
import SwiftUI

struct SessionRecord: Codable, Identifiable {
    var id: UUID
    var start, end: Date
    var phase: PomodoroPhase
    var activity: String          // 上位
    var detail:   String?         // 下位
}

class HistoryViewModel: ObservableObject {
    @Published private(set) var history: [SessionRecord] = []
    private let store = HistoryStore()              // 下で定義

    init() { history = store.load() }               // 起動時に読込

    // 保存
    func add(start: Date, end: Date,
            phase: PomodoroPhase,
            activity: String, detail: String?) {
        guard phase == .focus else { return } // ← 休憩は記録しない

        // 3秒未満は記録しない！
        // >= 3秒	誤タップではなく意図的操作とみなす最小限
        // >= 60秒	本気の集中だけに絞りたいならこっち（後で調整）
        let duration = end.timeIntervalSince(start)
        guard duration >= 3 else { return }

        let record = SessionRecord(
                        id: UUID(),
                        start: start,
                        end: end,
                        phase: phase,
                        activity: activity,
                        detail: detail
        )

        history.append(record)
        store.save(history)
    }

    func save() {
        store.save(history)
    }

    func updateLast(activity: String, detail: String) {
        guard history.indices.contains(history.count - 1) else { return }
        history[history.count - 1].activity = activity
        history[history.count - 1].detail   = detail
        save()
    }
}

