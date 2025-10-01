//
//  TimerNotificationManager.swift
//  TsukiUsagi
//
//  Created by Kazumi on 2025/01/01.
//

import Foundation
import Combine

/// タイマーの通知とハプティックフィードバックを担当するManager
@MainActor
final class TimerNotificationManager: ObservableObject {

    // MARK: - Dependencies

    private let notificationService: PhaseNotificationServiceable
    private let hapticService: HapticServiceable

    // MARK: - Published Properties

    @Published var shouldSuppressAnimation = false
    @Published var shouldSuppressSessionFinishedAnimation = false

    // MARK: - Initialization

    init(
        notificationService: PhaseNotificationServiceable,
        hapticService: HapticServiceable
    ) {
        self.notificationService = notificationService
        self.hapticService = hapticService
    }

    // MARK: - Notification Methods

    /// 開始通知を送信
    func sendStartNotification() {
        notificationService.sendStartNotification()
    }

    /// 通知権限を確認
    func ensureNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        notificationService.ensureAuthorizationIfNeeded(completion: completion)
    }

    /// 通知権限を確認（非同期版）
    func ensureNotificationAuthorization() async -> Bool {
        return await withCheckedContinuation { continuation in
            notificationService.ensureAuthorizationIfNeeded { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - Haptic Methods

    /// 重いハプティックフィードバック
    func triggerHeavyHaptic() {
        hapticService.heavyImpact()
    }

    /// 軽いハプティックフィードバック
    func triggerLightHaptic() {
        hapticService.lightImpact()
    }

    /// 成功ハプティックフィードバック（heavyImpactを使用）
    func triggerSuccessHaptic() {
        hapticService.heavyImpact()
    }

    // MARK: - Animation Control

    /// アニメーション抑制を設定
    func setAnimationSuppression(_ suppress: Bool) {
        shouldSuppressAnimation = suppress
    }

    /// セッション完了アニメーション抑制を設定
    func setSessionFinishedAnimationSuppression(_ suppress: Bool) {
        shouldSuppressSessionFinishedAnimation = suppress
    }

    /// アニメーション状態をリセット
    func resetAnimationState() {
        shouldSuppressAnimation = false
        shouldSuppressSessionFinishedAnimation = false
    }

    // MARK: - Background Handling

    /// アプリがバックグラウンドに入った時の処理
    func appDidEnterBackground() {
        // 通知権限の確認
        ensureNotificationAuthorization { granted in
            if granted {
                #if DEBUG
                print("🔔 通知許可: 承認済み")
                #endif
            } else {
                #if DEBUG
                print("🔔 通知許可: 拒否または未承認")
                #endif
            }
        }
    }

    /// アプリがフォアグラウンドに戻った時の処理
    func appWillEnterForeground() {
        // 通知の復元が必要かチェック
        recoverNotificationIfNeeded()
    }

    // MARK: - Private Methods

    /// 通知の復元が必要かチェック
    private func recoverNotificationIfNeeded() {
        // 実行中状態で通知が送信されていない場合の復元処理
        // 実装は必要に応じて追加
    }
}
