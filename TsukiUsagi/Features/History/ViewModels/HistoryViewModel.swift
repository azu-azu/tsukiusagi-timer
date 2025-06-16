import Foundation
import Combine
import SwiftUI

struct SessionRecord: Codable, Identifiable {
    let id: UUID
    let start: Date
    let end: Date
    let phase: PomodoroPhase   // focus / breakTime
    let label: String   // ← New!

    enum CodingKeys: String, CodingKey {
        case id, start, end, phase, label
    }
}

class HistoryViewModel: ObservableObject {
    @Published private(set) var history: [SessionRecord] = []
    private let store = HistoryStore()              // 下で定義

    init() { history = store.load() }               // 起動時に読込

    // 保存
    func add(start: Date, end: Date, phase: PomodoroPhase, label: String) {
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
                        label: label
        )

        history.append(record)
        store.save(history)
    }
}