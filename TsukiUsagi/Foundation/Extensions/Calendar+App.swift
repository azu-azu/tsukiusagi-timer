import Foundation

extension Calendar {
    /// Shared calendar configuration for history computations.
    static var app: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        calendar.timeZone = .current
        return calendar
    }()
}

enum HistoryDateKey {
    static func dayKey(for date: Date) -> Date {
        Calendar.app.startOfDay(for: date)
    }
}

