import Foundation

enum PomodoroPhase: String, Codable {
    case focus
    case breakTime

    mutating func toggle() {
        self = (self == .focus) ? .breakTime : .focus
    }

    var label: String {
        switch self {
        case .focus: return "集中"
        case .breakTime: return "休憩"
        }
    }
}
