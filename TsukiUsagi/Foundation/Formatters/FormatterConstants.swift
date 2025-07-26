import Foundation

/// Constants for time and date formatting
enum FormatterConstants {
    /// Time format constants
    enum TimeFormat {
        static let minutesSeconds = "%02d:%02d"
        static let hoursMinutes = "HH:mm"
        static let fallbackTime = "--:--"
    }

    /// Duration text templates
    enum DurationText {
        static let hoursAndMinutes = "%d h %d min"
        static let minutesOnly = "%d min"
    }
}
