import Foundation

struct CalendarUtilities {
    private static let calendar = Calendar.current

    /// 指定月の全日付を取得
    static func generateMonthDates(for date: Date) -> [Date] {
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return []
        }

        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }

    /// 曜日名を取得
    static func weekdays() -> [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortWeekdaySymbols
    }

    /// 今日かどうか判定
    static func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    /// 同じ月かどうか判定
    static func isSameMonth(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, equalTo: date2, toGranularity: .month)
    }

    /// 月の開始日を取得
    static func startOfMonth(for date: Date) -> Date {
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return date
        }
        return startOfMonth
    }

    /// 月の終了日を取得
    static func endOfMonth(for date: Date) -> Date {
        // 🔧 修正：関数呼び出しではなく直接計算
        guard let startOfMonthDate = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonthDate) else {
            return date
        }
        return endOfMonth
    }
}
