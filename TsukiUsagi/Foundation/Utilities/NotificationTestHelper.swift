import Foundation
import UserNotifications

/// 通知機能のテスト用ヘルパークラス
final class NotificationTestHelper {
    static let shared = NotificationTestHelper()

    private init() {}

    /// 通知機能の動作確認
    func testNotificationFunctionality() async {
        #if DEBUG
        print("🔔 通知機能テスト開始...")

        // 1. 通知許可状態の確認
        let permissionStatus = await NotificationPermissionManager.shared.getCurrentPermissionStatus()
        print("📱 通知許可状態: \(permissionStatus.rawValue)")

        // 2. NotificationManagerの動作確認
        let notificationManager = NotificationManager.shared

        // 3. 短時間のテスト通知をスケジュール
        print("⏰ 5秒後のテスト通知をスケジュール...")
        notificationManager.scheduleSessionEndNotification(after: 5, phase: .focus)

        // 4. 通知がスケジュールされたか確認
        let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        print("📋 スケジュール済み通知数: \(pendingRequests.count)")

        for request in pendingRequests {
            print("  - ID: \(request.identifier)")
            print("  - タイトル: \(request.content.title)")
            print("  - 本文: \(request.content.body)")
        }

        print("🔔 通知機能テスト完了")
        #endif
    }

    /// 通知をキャンセル
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        #if DEBUG
        print("🗑️ 全ての通知をキャンセルしました")
        #endif
    }
}