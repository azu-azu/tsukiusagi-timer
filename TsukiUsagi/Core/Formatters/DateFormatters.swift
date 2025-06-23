import Foundation

enum DateFormatters {
    /// yyyy/MM/dd EEE など『年も入った』日付。
    static let displayDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy/M/d EEE"
        return f
    }()

    /// M/d EEE  – 年を含まない表示専用
    static let displayDateNoYear: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "M/d EEE"
        return f
    }()
}