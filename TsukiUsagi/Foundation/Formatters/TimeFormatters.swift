import Foundation

/// Consolidated time formatting utilities
enum TimeFormatters {
    /// 秒数をMM:SS形式に変換
    static func formatTime(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: FormatterConstants.TimeFormat.minutesSeconds, minutes, remainingSeconds)
    }

    /// Date?をHH:mm形式に変換（nilなら--:--）
    static func formatTime(date: Date?) -> String {
        guard let date = date else { return FormatterConstants.TimeFormat.fallbackTime }
        let formatter = DateFormatter()
        formatter.dateFormat = FormatterConstants.TimeFormat.hoursMinutes
        return formatter.string(from: date)
    }
    
    /// 分を時間と分に変換して表示用の文字列を返す
    /// - Parameter totalMinutes: 総分数
    /// - Returns: フォーマットされた文字列（例：「2 h 30 min」または「45 min」）
    static func totalText(_ totalMinutes: Int) -> String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return String(format: FormatterConstants.DurationText.hoursAndMinutes, hours, minutes)
        } else {
            return String(format: FormatterConstants.DurationText.minutesOnly, minutes)
        }
    }
}

/// TimeFormatterUtil class implementation for protocol compatibility
final class TimeFormatterUtil: TimeFormatterUtilable {
    func format(seconds: Int) -> String {
        return TimeFormatters.formatTime(seconds: seconds)
    }

    func format(date: Date?) -> String {
        return TimeFormatters.formatTime(date: date)
    }
}
