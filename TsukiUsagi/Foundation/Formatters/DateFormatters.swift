import Foundation

enum DateFormatters {
    /// yyyy/MM/dd EEE など『年も入った』日付。
    static let displayDate: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy/M/d EEE"
        return dateFormatter
    }()

    /// M/d EEE  – 年を含まない表示専用
    static let displayDateNoYear: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "M/d EEE"
        return dateFormatter
    }()
}
