//
//  Month.swift
//  TsukiUsagi
//
//  Month model for stable TabView page management
//  Provides UUID-based stable identity for smooth page transitions
//

import Foundation

/// Month model with stable UUID for TabView page management
struct Month: Identifiable, Equatable {
    let id: UUID = UUID()
    let date: Date

    /// Initialize with a specific date
    init(date: Date) {
        self.date = date
    }

    /// Generate months around today
    static func generateAroundToday(countBefore: Int, countAfter: Int) -> [Month] {
        let calendar = Calendar.current
        let today = Date()
        let baseMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today

        var result: [Month] = []
        for i in (-countBefore)...countAfter {
            if let monthDate = calendar.date(byAdding: .month, value: i, to: baseMonthStart) {
                result.append(Month(date: monthDate))
            }
        }
        return result
    }

    /// Get the start of this month
    var startOfMonth: Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    /// Check if this month is the current month
    var isCurrentMonth: Bool {
        let calendar = Calendar.current
        return calendar.isDate(date, equalTo: Date(), toGranularity: .month)
    }

    /// Formatted month title
    var title: String {
        date.formatted(.dateTime.year().month(.wide))
    }
}

// MARK: - Convenience Extensions

extension Comparable {
    /// Clamp value to a closed range
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
