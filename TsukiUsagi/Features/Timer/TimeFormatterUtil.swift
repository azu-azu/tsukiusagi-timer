import Foundation

protocol TimeFormatterUtilable: AnyObject {
    func format(seconds: Int) -> String
    func format(date: Date?) -> String
}

final class TimeFormatterUtil: TimeFormatterUtilable {
    func format(seconds: Int) -> String {
        // 秒数をmm:ss形式などに変換
        return ""
    }
    func format(date: Date?) -> String {
        // 日付を表示用に変換
        return ""
    }
}
