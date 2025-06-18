import Foundation

enum AppFormatters {
    /// 表示用日付：2025/6/17 Tue
    static let displayDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/M/d EEE"
        f.locale = Locale(identifier: "en_US")
        return f
    }()
}
