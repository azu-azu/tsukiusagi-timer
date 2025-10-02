import Foundation

extension Date {
    /// Returns the start of the week (Sunday) for this date
    var startOfWeek: Date {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    /// Returns the day of week as integer (0 = Sunday, 1 = Monday, ..., 6 = Saturday)
    var dayOfWeek: Int {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        return calendar.component(.weekday, from: self) - 1
    }

    /// Checks if this date is the same day as another date
    func isSameDay(as other: Date) -> Bool {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        return calendar.isDate(self, inSameDayAs: other)
    }

    /// Checks if this date is the consecutive day after another date
    func isConsecutiveDay(after other: Date) -> Bool {
        guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: other) else {
            return false
        }
        return self.isSameDay(as: nextDay)
    }

    /// Returns the date for a specific day of the week within the same week
    func dateForDayOfWeek(_ dayOfWeek: Int) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current

        let today = calendar.startOfDay(for: self)
        let currentWeekday = calendar.component(.weekday, from: today) - 1
        var offset = dayOfWeek - currentWeekday
        if offset < 0 { offset += 7 }

        let result = calendar.date(byAdding: .day, value: offset, to: today) ?? self


        return result
    }

    /// Returns a short day name (Su, Mo, Tu, etc.)
    var shortDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        let fullName = formatter.string(from: self)
        return String(fullName.prefix(2))
    }
}
