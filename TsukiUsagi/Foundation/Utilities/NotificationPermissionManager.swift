import Foundation
import UserNotifications
import UIKit

/// 通知許可の管理を行うユーティリティクラス
final class NotificationPermissionManager {
    static let shared = NotificationPermissionManager()

    private let userDefaults = UserDefaults.standard
    private let notificationCenter = UNUserNotificationCenter.current()

    private let hasRequestedPermissionKey = "has_requested_notification_permission"

    private init() {}

    /// 初回起動かどうかを判定
    var isFirstLaunch: Bool {
        return !userDefaults.bool(forKey: hasRequestedPermissionKey)
    }

    /// 通知許可をリクエスト（初回起動時のみ）
    func requestPermissionIfNeeded() async -> Bool {
        // 既に許可済みの場合は何もしない
        let currentStatus = await notificationCenter.notificationSettings()
        if currentStatus.authorizationStatus == .authorized {
            return true
        }

        // 初回起動でない場合は何もしない
        guard isFirstLaunch else {
            return currentStatus.authorizationStatus == .authorized
        }

        // 初回起動時のみ許可をリクエスト
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])

            // リクエスト済みフラグを設定
            userDefaults.set(true, forKey: hasRequestedPermissionKey)
            _ = granted

            return granted
        } catch {
            userDefaults.set(true, forKey: hasRequestedPermissionKey)
            return false
        }
    }

    // MARK: - Unified (timeSensitive) Authorization

    /// iOS 15+ の timeSensitive を含めて統一的に許可を整える
    /// - Returns: 利用可能かどうか（timeSensitive 前提環境では、iOS15+ で timeSensitive が無効なら false）
    @discardableResult
    func ensureUnifiedAuthorization(openSettingsIfNeeded: Bool = false) async -> Bool {
        let center = notificationCenter
        let settings = await center.notificationSettings()

        // notDetermined → 初回リクエスト（timeSensitive entitlement は Info.plist で設定）
        if settings.authorizationStatus == .notDetermined {
            do {
                if #available(iOS 15.0, *) {
                    let granted = try await center.requestAuthorization(
                        options: [
                            .alert,
                            .badge,
                            .sound
                        ]
                    )
                    userDefaults.set(true, forKey: hasRequestedPermissionKey)
                    return granted
                } else {
                    let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                    userDefaults.set(true, forKey: hasRequestedPermissionKey)
                    return granted
                }
            } catch {
                userDefaults.set(true, forKey: hasRequestedPermissionKey)
                return false
            }
        }

        // authorized/provisional/ephemeral の場合、iOS15+ では timeSensitiveSetting も確認
        if #available(iOS 15.0, *) {
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                if settings.timeSensitiveSetting != .enabled {
                    if openSettingsIfNeeded {
                        await openSettingsAsync()
                    }
                    return false
                }
                return true
            default:
                return false
            }
        } else {
            // iOS14 以下は通常の authorized のみ確認
            return settings.authorizationStatus == .authorized
        }
    }

    private func openSettingsAsync() async {
        await MainActor.run {
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        }
    }

    /// 現在の通知許可状態を取得
    func getCurrentPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    /// 通知許可が承認されているかどうか
    func isPermissionGranted() async -> Bool {
        let status = await getCurrentPermissionStatus()
        return status == .authorized
    }

    /// アプリの設定画面を開く
    func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    /// 通知許可が拒否されているかどうか
    func isPermissionDenied() async -> Bool {
        let status = await getCurrentPermissionStatus()
        return status == .denied
    }

    /// 通知許可の状態に応じたガイダンスメッセージを取得
    func getGuidanceMessage() async -> String {
        let status = await getCurrentPermissionStatus()
        switch status {
        case .authorized:
            return "通知は有効です。バックグラウンド時も終了通知を受け取れます。"
        case .denied:
            return "通知が無効です。設定から通知を有効にしてください。"
        case .notDetermined:
            return "通知の許可が必要です。アプリの機能を最大限活用するために許可してください。"
        case .provisional:
            return "一時的な通知許可が有効です。"
        case .ephemeral:
            return "一時的な通知許可が有効です。"
        @unknown default:
            return "通知の状態を確認できません。"
        }
    }
}
