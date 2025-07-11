import Foundation

enum TimeFormatters {
    /// 秒数をMM:SS形式に変換
    static func formatTime(seconds: Int) -> String {
        let minutes = seconds / 60, seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Date?をHH:mm形式に変換（nilなら--:--）
    static func formatTime(date: Date?) -> String {
        guard let date = date else { return "--:--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
