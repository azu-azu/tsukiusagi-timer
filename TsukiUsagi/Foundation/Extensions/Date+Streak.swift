import Foundation

extension Date {
    /// Returns the start of the week (Sunday) for this date
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    /// Returns the day of week as integer (0 = Sunday, 1 = Monday, ..., 6 = Saturday)
    var dayOfWeek: Int {
        let calendar = Calendar.current
        return calendar.component(.weekday, from: self) - 1
    }

    /// Checks if this date is the same day as another date
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
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
        let calendar = Calendar.current
        let startOfWeek = self.startOfWeek
        return calendar.date(byAdding: .day, value: dayOfWeek, to: startOfWeek) ?? self
    }

    /// Returns a short day name (Su, Mo, Tu, etc.)
    var shortDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        let fullName = formatter.string(from: self)
        return String(fullName.prefix(2))
    }
}
