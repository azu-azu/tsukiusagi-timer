//
//  NotificationManager.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/14
//

import Foundation
import UserNotifications

// PomodoroPhase は既にプロジェクト内で定義されているので再宣言しない

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {
        setupNotificationCategories()
    }

    // 通知カテゴリの設定（Deep Link対応）
    private func setupNotificationCategories() {
        let timerAction = UNNotificationAction(
            identifier: "OPEN_TIMER",
            title: "タイマーを開く",
            options: [.foreground]
        )

        let timerCategory = UNNotificationCategory(
            identifier: "TIMER_CATEGORY",
            actions: [timerAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([timerCategory])
    }

    // 権限リクエスト
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error = error {
                    #if DEBUG
                    print("通知許可リクエスト失敗: \(error.localizedDescription)")
                    #endif
                    completion(false); return
                }
                completion(granted)
            }
    }

    // 権限確認
    private func checkNotificationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current()
            .getNotificationSettings { settings in
                DispatchQueue.main.async {
                    completion(settings.authorizationStatus == .authorized)
                }
            }
    }

    // ★ フェーズに応じて通知
    func sendPhaseChangeNotification(for phase: PomodoroPhase) {
        checkNotificationStatus { [weak self] allowed in
            guard allowed else {
                #if DEBUG
                print("通知は許可されていません")
                #endif
                return
            }
            self?.schedule(for: phase)
        }
    }

    // 指定秒後にセッション終了通知をスケジューリング（TimeInterval版 - 後方互換性のため残す）
    func scheduleSessionEndNotification(after seconds: Int, phase: PomodoroPhase) {
        let endAt = Date().addingTimeInterval(TimeInterval(seconds))
        scheduleSessionEndNotification(at: endAt, phase: phase, timeSensitive: false)
    }

    // 絶対時刻でセッション終了通知をスケジューリング（推奨）
    func scheduleSessionEndNotification(at endAt: Date, phase: PomodoroPhase, timeSensitive: Bool = false) {
        checkNotificationStatus { [weak self] allowed in
            guard allowed else { return }
            Task { [weak self] in
                await self?.ensureSingleNotification()
                await MainActor.run { [weak self] in
                    self?.scheduleNotificationAtAbsoluteTime(endAt: endAt, phase: phase, timeSensitive: timeSensitive)
                }
            }
        }
    }

    // 絶対時刻での通知スケジューリング実装
    private func scheduleNotificationAtAbsoluteTime(endAt: Date, phase: PomodoroPhase, timeSensitive: Bool) {
        let content = UNMutableNotificationContent()
        switch phase {
        case .focus:
            content.title = "Time to Rest 🌑"
            content.body = "The moon is still. So can you be."
        case .breakTime:
            content.title = "Time to Focus 🌕"
            content.body = "Let's begin, quietly centered."
        }
        content.sound = .default
        content.categoryIdentifier = "TIMER_CATEGORY" // Deep Link対応

        // Time-Sensitive対応（iOS 15+）
        if #available(iOS 15.0, *), timeSensitive {
            content.interruptionLevel = .timeSensitive
        }

        // 絶対時刻でのトリガー設定
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: endAt
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // 重複防止：既存通知を削除してから追加
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["SessionEnd"])
        let request = UNNotificationRequest(
            identifier: "SessionEnd",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                #if DEBUG
                print("🔔 通知スケジューリング失敗: \(error.localizedDescription)")
                #endif
            } else {
                #if DEBUG
                print("🔔 通知スケジューリング成功: \(endAt)")
                #endif
            }
        }
    }

    // セッション終了通知をキャンセル
    func cancelSessionEndNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["SessionEnd"])
    }

    // 重複通知の完全防止：既存通知をチェックしてからスケジューリング
    private func ensureSingleNotification() async {
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()

        // SessionEnd通知が複数ある場合は全て削除
        let sessionEndRequests = pendingRequests.filter { $0.identifier == "SessionEnd" }
        if sessionEndRequests.count > 1 {
            #if DEBUG
            print("🔔 重複通知を検出: \(sessionEndRequests.count)件 → 全て削除")
            #endif
            center.removePendingNotificationRequests(withIdentifiers: ["SessionEnd"])
        }
    }

    // 内部: 通知作成
    private func schedule(for phase: PomodoroPhase) {
        let content = UNMutableNotificationContent()

        switch phase {
        case .focus:
            content.title = "Time to Focus 🌕"
            content.body = "Let's begin, quietly centered."
        case .breakTime:
            content.title = "Time to Rest 🌑"
            content.body = "The moon is still. So can you be."
        }

        // 音＋バイブ
        content.sound = .default

        // 毎回ユニーク ID で通知センターに積む
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                #if DEBUG
                print("通知失敗: \(error.localizedDescription)")
                #endif
            } else {
                #if DEBUG
                print("通知成功")
                #endif
            }
        }
    }
}
