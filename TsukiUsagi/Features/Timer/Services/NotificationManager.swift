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
                return
            }
            #if DEBUG
            print("log: phase_send=\(phase)")
            #endif
            self?.schedule(for: phase)
        }
    }

    /// テスト用：即時通知を送信
    func sendTestNotification(for phase: PomodoroPhase) {
        let content = UNMutableNotificationContent()

        switch phase {
        case .focus:
            content.title = "Time to Focus 🌕"
            content.body = "Let's begin, quietly centered."
        case .breakTime:
            content.title = "Time to Rest 🌑"
            content.body = "The moon is still. So can you be."
        }

        content.sound = .default
        content.categoryIdentifier = "TIMER_CATEGORY"

        let request = UNNotificationRequest(
            identifier: "test_\(phase)_\(UUID().uuidString)",
            content: content,
            trigger: nil // 即座に送信
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                #if DEBUG
                print("🔔 テスト通知失敗 (\(phase)): \(error.localizedDescription)")
                #endif
            } else {
                #if DEBUG
                print("🔔 テスト通知成功 (\(phase))")
                #endif
            }
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
        let now = Date()
        let delta = endAt.timeIntervalSince(now)

        #if DEBUG
        print("log: schedule_absolute phase=\(phase) at=\(endAt) delta=\(Int(delta))s timeSensitive=\(timeSensitive)")
        #endif

        // 通知IDをフェーズ別に分ける
        let id = (phase == .focus) ? "SessionEnd.focus" : "SessionEnd.break"

        // 既存の同フェーズ通知をキャンセル
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        switch phase {
        case .focus:
            content.title = "Time to Focus 🌕"
            content.body = "Let's begin, quietly centered."
            content.threadIdentifier = "pomodoro.focus"
        case .breakTime:
            content.title = "Time to Rest 🌑"
            content.body = "The moon is still. So can you be."
            content.threadIdentifier = "pomodoro.break"
        }
        content.sound = .default
        content.categoryIdentifier = "TIMER_CATEGORY"

        // Time-Sensitive対応（iOS 15+）
        if #available(iOS 15.0, *), timeSensitive {
            content.interruptionLevel = .timeSensitive
        }

        // 安全策：秒未満は切り上げ、1秒未満の場合はTimeIntervalTriggerを使用
        var trigger: UNNotificationTrigger
        if delta >= 1 {
            var components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: endAt
            )
            // 安全策：秒未満は切り上げ
            if let s = components.second, s < 0 { components.second = 0 }
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        }

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { _ in }
    }

    // セッション終了通知をキャンセル
    func cancelSessionEndNotification() {

        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["SessionEnd.focus", "SessionEnd.break"]
        )
    }

    // 重複通知の完全防止：既存通知をチェックしてからスケジューリング
    private func ensureSingleNotification() async {
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()

        // SessionEnd通知が複数ある場合は全て削除
        let sessionEndRequests = pendingRequests.filter { $0.identifier.hasPrefix("SessionEnd") }
        if sessionEndRequests.count > 1 {

            center.removePendingNotificationRequests(withIdentifiers: ["SessionEnd.focus", "SessionEnd.break"])
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

        UNUserNotificationCenter.current().add(request) { _ in }
    }

}
