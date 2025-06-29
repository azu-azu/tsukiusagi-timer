import Foundation

/// 時間フォーマット関連の共通関数
struct TimeFormatting {

    /// 分を時間と分に変換して表示用の文字列を返す
    /// - Parameter totalMinutes: 総分数
    /// - Returns: フォーマットされた文字列（例：「2 h 30 min」または「45 min」）
    static func totalText(_ totalMinutes: Int) -> String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours) h \(minutes) min"
        } else {
            return "\(minutes) min"
        }
    }
}