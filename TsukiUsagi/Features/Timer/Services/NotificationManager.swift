//
//  NotificationManager.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/14
//

import Foundation
import UserNotifications
import UIKit
#if DEBUG
import os
#endif

// PomodoroPhase は既にプロジェクト内で定義されているので再宣言しない

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {
        setupNotificationCategories()
    }

    // BG挙動チューニング用の定数（スタガのみ採用）
    private let bgFocusStaggerSeconds: TimeInterval = 5.0

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
    func scheduleSessionEndNotification(
        at endAt: Date,
        phase: PomodoroPhase,
        timeSensitive: Bool = false,
        cleanupPendingPrefixes: Bool = true
    ) {
        checkNotificationStatus { [weak self] allowed in
            guard allowed else { return }
            Task { [weak self] in
                // 予約前の pending 整理（必要に応じて）
                if cleanupPendingPrefixes {
                    await self?.removePendingForPrefix(NotificationID.focus)
                    await self?.removePendingForPrefix(NotificationID.rest)
                }
                await MainActor.run { [weak self] in
                    self?.scheduleNotificationAtAbsoluteTime(endAt: endAt, phase: phase, timeSensitive: timeSensitive)
                }
            }
        }
    }

    // 絶対時刻での通知スケジューリング実装
    private func scheduleNotificationAtAbsoluteTime(endAt: Date, phase: PomodoroPhase, timeSensitive: Bool) {
        // BGでは Focus を数秒スタガして同時刻合流を避ける
        var targetEndAt = endAt
        if UIApplication.shared.applicationState != .active, phase == .focus {
            targetEndAt = endAt.addingTimeInterval(bgFocusStaggerSeconds)
        }
        let now = Date()
        let delta = targetEndAt.timeIntervalSince(now)

        // debug removed

        // 通知ID: フェーズ別プリフィクス + ユニークサフィックス（抑制回避）
        let prefix = id(for: phase)
        let uniqueId = "\(prefix).\(Int(targetEndAt.timeIntervalSince1970)).\(UUID().uuidString.prefix(8))"

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
        // スレッド識別子: FGはprefixでグルーピング、BGは一意IDで合流抑止
        if UIApplication.shared.applicationState == .active {
            content.threadIdentifier = prefix
        } else {
            content.threadIdentifier = uniqueId
        }

        // Time-Sensitive対応（iOS 15+）
        if #available(iOS 15.0, *), timeSensitive {
            content.interruptionLevel = .timeSensitive
        }
        // BGでは Rest を過度に強くしない（Focusを表に出すため）
        if UIApplication.shared.applicationState != .active {
            if #available(iOS 15.0, *), phase == .breakTime {
                // Restは通常レベルに抑える（直前のRestが残っていても次のFocusを出しやすくする）
                content.interruptionLevel = .active
            }
        }

        // 予約直前の整理は「同フェーズの古い delivered のみ」に限定（前フェーズはFGのwillPresentで処理）
        clearDeliveredSamePhaseOnly(forIncomingId: uniqueId, phase: phase)

        // （BG one-at-a-time 無効化）前フェーズの無条件削除は行わない

        // 安全策：秒未満は切り上げ、1秒未満の場合はTimeIntervalTriggerを使用
        var trigger: UNNotificationTrigger
        if delta >= 1 {
            var components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: targetEndAt
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

    // 廃止: 広域cleanup（未使用のため削除）

    // 対象プリフィクスの pending をすべて削除（重複/残留対策）
    private func removePendingForPrefix(_ prefix: String) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map { $0.identifier }.filter { $0.hasPrefix(prefix) }
        if !ids.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Public pending cleanup helpers

    /// フェーズ単位で pending を削除（prefix一致）
    func removePending(for phase: PomodoroPhase) {
        Task { [weak self] in
            guard let self else { return }
            await self.removePendingForPrefix(self.id(for: phase))
        }
    }

    // MARK: - Delivered cleanup helpers (scoped)

    /// 同フェーズの古い delivered のみを予約直前に整理（incomingと同一IDは残す）
    func clearDeliveredSamePhaseOnly(forIncomingId id: String, phase: PomodoroPhase) {
        let samePrefix = self.id(for: phase)
        UNUserNotificationCenter.current().getDeliveredNotifications { notes in
            let targets = notes
                .map { $0.request.identifier }
                .filter { $0.hasPrefix(samePrefix) && $0 != id }
            if !targets.isEmpty {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: targets)
            }
        }
    }

    /// 前フェーズの delivered のみを整理（同フェーズは触らない）
    func clearPreviousPhaseDeliveredOnly(forIncoming incomingId: String) {
        let isFocusIncoming = incomingId.hasPrefix(NotificationID.focus)
        let prevPrefix = isFocusIncoming ? NotificationID.rest : NotificationID.focus
        UNUserNotificationCenter.current().getDeliveredNotifications { notes in
            let ids = notes
                .map { $0.request.identifier }
                .filter { $0.hasPrefix(prevPrefix) && $0 != incomingId }
            if !ids.isEmpty {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
            }
        }
    }

    /// 複数フェーズの pending を削除（prefix一致）
    func removePending(for phases: [PomodoroPhase]) {
        Task { [weak self] in
            guard let self else { return }
            for p in phases {
                await self.removePendingForPrefix(self.id(for: p))
            }
        }
    }

    /// セッション終了通知（Focus/Rest）の pending を prefix 単位で全削除
    /// 一意ID (prefix.epoch.uuid) 方式と整合させるため、Exact-ID ではなく prefix ベースで掃除する
    func removeAllSessionEndPendingByPrefix() {
        Task { [weak self] in
            guard let self else { return }
            await self.removePendingForPrefix(NotificationID.focus)
            await self.removePendingForPrefix(NotificationID.rest)
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

    // MARK: - Sequenced helpers for robust scheduling

    /// 連鎖（2本）予約を順序保証で実行（初回のみpending掃除 → Work→Rest, Rest→Focus の順に予約）
    func scheduleChainedSessionEnds(workEndAt: Date, breakEndAt: Date, timeSensitive: Bool) {
        checkNotificationStatus { [weak self] allowed in
            guard allowed else { return }
            Task { [weak self] in
                guard let self else { return }
                // 初回に両prefixのpendingを掃除
                await self.removePendingForPrefix(NotificationID.focus)
                await self.removePendingForPrefix(NotificationID.rest)
                // Work→Rest
                await MainActor.run { [weak self] in
                    self?.scheduleNotificationAtAbsoluteTime(
                        endAt: workEndAt,
                        phase: .breakTime,
                        timeSensitive: timeSensitive
                    )
                }
                // Rest→Focus
                await MainActor.run { [weak self] in
                    self?.scheduleNotificationAtAbsoluteTime(
                        endAt: breakEndAt,
                        phase: .focus,
                        timeSensitive: timeSensitive
                    )
                }
            }
        }
    }

    /// Focusのみ、prefix掃除のあとに順序保証で予約
    func scheduleFocusAfterClearingPending(at breakEndAt: Date, timeSensitive: Bool) {
        checkNotificationStatus { [weak self] allowed in
            guard allowed else { return }
            Task { [weak self] in
                guard let self else { return }
                await self.removePendingForPrefix(NotificationID.focus)
                await MainActor.run { [weak self] in
                    self?.scheduleNotificationAtAbsoluteTime(
                        endAt: breakEndAt,
                        phase: .focus,
                        timeSensitive: timeSensitive
                    )
                }
            }
        }
    }

}
