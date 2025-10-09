import Foundation

/// Persisted reflection text for a specific day.
struct DayReflection: Codable, Equatable {
    var date: Date
    var text: String
    var lastUpdatedAt: Date
    var isPendingSave: Bool
}
