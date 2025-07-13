import Foundation

protocol TimeFormatterUtilable: AnyObject {
    func format(seconds: Int) -> String
    func format(date: Date?) -> String
}

final class TimeFormatterUtil: TimeFormatterUtilable {
    func format(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    func format(date: Date?) -> String {
        guard let date = date else { return "--:--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
