import Foundation
import UserNotifications

/// 通知機能のテスト用ヘルパークラス
final class NotificationTestHelper {
    static let shared = NotificationTestHelper()

    private init() {}

    /// 通知機能の動作確認
    func testNotificationFunctionality() async {
        // (debug logs removed)
    }

    /// 通知をキャンセル
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
