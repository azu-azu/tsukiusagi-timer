import Foundation

/// Protocol for time formatting utilities
protocol TimeFormatterUtilable: AnyObject {
    func format(seconds: Int) -> String
    func format(date: Date?) -> String
}
