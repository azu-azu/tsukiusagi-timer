//
//  NotificationManager.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/14
//

import Foundation
import UserNotifications
#if DEBUG
import os
import UIKit
#endif

// PomodoroPhase は既にプロジェクト内で定義されているので再宣言しない

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {
        setupNotificationCategories()
    }

    // MARK: - Phase-scoped identifiers
    enum NotificationID {
        static let focus = "SessionEnd.focus"
        static let rest  = "SessionEnd.break"
    }

    func id(for phase: PomodoroPhase) -> String {
        return (phase == .focus) ? NotificationID.focus : NotificationID.rest
    }

    // 直近に発行したidentifierを記録（delivered明示削除用、最小限の保持）
    private var lastIssuedIdForPhase: [PomodoroPhase: String] = [:]

    // Debug logging helpers removed (🌙TSK)

    // 通知カテゴリの設定（Deep Link対応）
    private func setupNotificationCategories() {
        let openTimer = UNNotificationAction(
            identifier: "OPEN_TIMER",
            title: "タイマーを開く",
            options: [.foreground]
        )

        let focusCategory = UNNotificationCategory(
            identifier: "TIMER_FOCUS",
            actions: [openTimer],
            intentIdentifiers: [],
            options: []
        )

        let restCategory = UNNotificationCategory(
            identifier: "TIMER_REST",
            actions: [openTimer],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([focusCategory, restCategory])
    }

    // 権限リクエスト
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { granted, error in
                if error != nil {
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
                // 予約前に全フェーズの pending を接頭辞で整理（取りこぼし防止）
                await self?.removePendingForPrefix(NotificationID.focus)
                await self?.removePendingForPrefix(NotificationID.rest)
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

        // debug removed

        // 通知ID: フェーズ別プリフィクス + ユニークサフィックス（抑制回避）
        let prefix = id(for: phase)
        let uniqueId = "\(prefix).\(Int(endAt.timeIntervalSince1970))"

        let content = UNMutableNotificationContent()
        switch phase {
        case .focus:
            content.title = "Time to Focus 🌕"
            content.body = "Let's begin, quietly centered."
            content.categoryIdentifier = "TIMER_FOCUS"
        case .breakTime:
            content.title = "Time to Rest 🌑"
            content.body = "The moon is still. So can you be."
            content.categoryIdentifier = "TIMER_REST"
        }
        content.sound = .default
        // 次フェーズ識別のため userInfo に埋め込む
        content.userInfo = ["phase": (phase == .focus ? "focus" : "breakTime")]
        // 1つ前の delivered が残っていても抑制されないよう、threadIdentifier もユニーク化
        content.threadIdentifier = uniqueId

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
            identifier: uniqueId,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { _ in }
        // debug removed
        // 記録
        lastIssuedIdForPhase[phase] = uniqueId
    }

    // セッション終了通知をキャンセル（既定: pending のみ）
    func cancelSessionEndNotification() {
        cancelSessionEndNotifications()
    }

    /// 柔軟な取消: 既定は pending のみ。必要時に delivered も削除
    func cancelSessionEndNotifications(
        ids: [String] = [NotificationID.focus, NotificationID.rest],
        removeDelivered: Bool = false,
        removePending: Bool = true
    ) {
        let center = UNUserNotificationCenter.current()
        if removePending {
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
        if removeDelivered {
            center.removeDeliveredNotifications(withIdentifiers: ids)
        }
    }

    /// 明示的に delivered を掃除（復旧・手動クリア等）
    func clearDelivered(ids: [String] = [NotificationID.focus, NotificationID.rest]) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
    }

    /// 直近に発行した同フェーズの delivered を正確なIDで削除
    func clearLastDelivered(for phase: PomodoroPhase) {
        if let lastId = lastIssuedIdForPhase[phase] {
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [lastId])
        }
    }

    // clearPreviousPhaseDeliveredIfNeeded は抑制解除に副作用があるため撤去

    /// 新規通知のidentifierからフェーズを推定し、
    /// 1) 反対フェーズの直近 delivered
    /// 2) 同一フェーズの古い delivered（incomingとは別ID）
    /// を提示直前に整理する（OS抑制度合いの差異対策）。
    func clearPreviousPhaseDeliveredForIncoming(identifier: String) {
        let isFocusIncoming = identifier.hasPrefix(NotificationID.focus)
        let prevPhase: PomodoroPhase = isFocusIncoming ? .breakTime : .focus
        let samePhase: PomodoroPhase = isFocusIncoming ? .focus : .breakTime

        let center = UNUserNotificationCenter.current()
        // 反対フェーズを整理（正確なID指定）
        if let lastPrev = lastIssuedIdForPhase[prevPhase] {
            center.removeDeliveredNotifications(withIdentifiers: [lastPrev])
        }
        // 同一フェーズの古い delivered を整理（incoming と同一IDは残す）
        if let lastSame = lastIssuedIdForPhase[samePhase], lastSame != identifier {
            center.removeDeliveredNotifications(withIdentifiers: [lastSame])
        }
    }

    // 対象プリフィクスの pending をすべて削除（重複/残留対策）
    private func removePendingForPrefix(_ prefix: String) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map { $0.identifier }.filter { $0.hasPrefix(prefix) }
        if !ids.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: ids)
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
