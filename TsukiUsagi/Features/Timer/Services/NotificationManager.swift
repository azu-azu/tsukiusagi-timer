//
//  NotificationManager.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/14
//

import Foundation
import UserNotifications
import UIKit

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

    /// 直近に発行したidentifierを記録
    var lastIssuedIdForPhase: [PomodoroPhase: String] = [:]

    // MARK: - Authorization

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current()
            .requestAuthorization(options: options) { granted, error in
                if error != nil {
                    completion(false)
                    return
                }
                completion(granted)
            }
    }

    // MARK: - Phase Change Notification

    func sendPhaseChangeNotification(for phase: PomodoroPhase) {
        checkNotificationStatus { [weak self] allowed in
            guard allowed else { return }
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
            content.categoryIdentifier = "TIMER_FOCUS"
        case .breakTime:
            content.title = "Time to Rest 🌑"
            content.body = "The moon is still. So can you be."
            content.categoryIdentifier = "TIMER_REST"
        }
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "test_\(phase)_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { _ in }
    }

    // MARK: - Session End Scheduling

    func scheduleSessionEndNotification(after seconds: Int, phase: PomodoroPhase) {
        let endAt = Date().addingTimeInterval(TimeInterval(seconds))
        scheduleSessionEndNotification(at: endAt, phase: phase, timeSensitive: true)
    }

    func scheduleSessionEndNotification(
        at endAt: Date,
        phase: PomodoroPhase,
        timeSensitive: Bool = true,
        cleanupPendingPrefixes: Bool = true
    ) {
        checkNotificationStatus { [weak self] allowed in
            guard allowed else { return }
            Task { [weak self] in
                if cleanupPendingPrefixes {
                    if let phaseId = self?.id(for: phase) {
                        await self?.removePendingForPrefix(phaseId)
                    }
                }
                await MainActor.run { [weak self] in
                    self?.scheduleNotificationAtAbsoluteTime(
                        endAt: endAt,
                        phase: phase,
                        timeSensitive: timeSensitive
                    )
                }
            }
        }
    }

    // MARK: - Cancellation

    func cancelSessionEndNotification() {
        cancelSessionEndNotifications()
    }

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

    func clearDelivered(ids: [String] = [NotificationID.focus, NotificationID.rest]) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
    }

    func clearLastDelivered(for phase: PomodoroPhase) {
        if let lastId = lastIssuedIdForPhase[phase] {
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [lastId])
        }
    }

    // MARK: - Pending Cleanup

    func removePending(for phase: PomodoroPhase) {
        Task { [weak self] in
            guard let self else { return }
            await self.removePendingForPrefix(self.id(for: phase))
        }
    }

    func removePending(for phases: [PomodoroPhase]) {
        Task { [weak self] in
            guard let self else { return }
            for p in phases {
                await self.removePendingForPrefix(self.id(for: p))
            }
        }
    }

    func removeAllSessionEndPendingByPrefix() {
        Task { [weak self] in
            guard let self else { return }
            await self.removePendingForPrefix(NotificationID.focus)
            await self.removePendingForPrefix(NotificationID.rest)
        }
    }

    func cancelSessionEndAll() {
        Task { [weak self] in
            guard let self else { return }
            await self.removePendingForPrefix(NotificationID.focus)
            await self.removePendingForPrefix(NotificationID.rest)
        }
    }

    // MARK: - Chained Scheduling

    func scheduleChainedSessionEnds(workEndAt: Date, breakEndAt: Date, timeSensitive: Bool) {
        checkNotificationStatus { [weak self] allowed in
            guard allowed else { return }
            Task { [weak self] in
                guard let self else { return }
                let center = UNUserNotificationCenter.current()
                let pending = await center.pendingNotificationRequests()
                let sessionEnds = pending.filter { $0.identifier.hasPrefix("SessionEnd.") }
                if sessionEnds.count >= 2 { return }

                await self.removePendingForPrefix(NotificationID.focus)
                await self.removePendingForPrefix(NotificationID.rest)

                await MainActor.run { [weak self] in
                    self?.scheduleNotificationAtAbsoluteTime(
                        endAt: workEndAt,
                        phase: .breakTime,
                        timeSensitive: timeSensitive
                    )
                }
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

    // MARK: - Private Setup

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

    func checkNotificationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current()
            .getNotificationSettings { settings in
                let allowed: Bool
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    allowed = true
                default:
                    allowed = false
                }
                DispatchQueue.main.async { completion(allowed) }
            }
    }
}
