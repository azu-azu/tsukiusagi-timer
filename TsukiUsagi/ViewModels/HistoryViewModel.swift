import Foundation
import Combine
import SwiftUI

struct SessionRecord: Codable, Identifiable {
    let id = UUID()
    let start: Date
    let end: Date
    let phase: PomodoroPhase   // focus / breakTime

    enum CodingKeys: String, CodingKey {
        case start, end, phase
    }
}

class HistoryViewModel: ObservableObject {
    @Published private(set) var history: [SessionRecord] = []
    private let store = HistoryStore()              // 下で定義

    init() { history = store.load() }               // 起動時に読込

    func add(start: Date, end: Date, phase: PomodoroPhase) {
        history.append(SessionRecord(start: start, end: end, phase: phase))
        // store.save(history)                         // すぐ保存
    }
}