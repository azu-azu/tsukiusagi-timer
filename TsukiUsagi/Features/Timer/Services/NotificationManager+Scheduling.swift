import Foundation
import UserNotifications
import UIKit

// MARK: - Scheduling Implementation

extension NotificationManager {
    /// 絶対時刻での通知スケジューリング実装
    func scheduleNotificationAtAbsoluteTime(endAt: Date, phase: PomodoroPhase, timeSensitive: Bool) {
        let targetEndAt = adjustedEndDate(for: endAt, phase: phase)
        let uniqueId = makeNotificationIdentifier(for: phase, targetEndAt: targetEndAt)
        let content = makeNotificationContent(for: phase, uniqueId: uniqueId, timeSensitive: timeSensitive)

        clearDeliveredSamePhaseOnly(forIncomingId: uniqueId, phase: phase)

        let trigger = makeNotificationTrigger(for: targetEndAt)
        submitNotification(id: uniqueId, content: content, trigger: trigger, phase: phase)
    }

    func adjustedEndDate(for endAt: Date, phase: PomodoroPhase) -> Date {
        return endAt
    }

    func makeNotificationIdentifier(for phase: PomodoroPhase, targetEndAt: Date) -> String {
        let prefix = id(for: phase)
        let timestamp = Int(targetEndAt.timeIntervalSince1970)
        let suffix = UUID().uuidString.prefix(8)
        return "\(prefix).\(timestamp).\(suffix)"
    }

    func makeNotificationContent(
        for phase: PomodoroPhase,
        uniqueId: String,
        timeSensitive: Bool
    ) -> UNMutableNotificationContent {
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
        content.userInfo = ["phase": (phase == .focus ? "focus" : "breakTime")]
        content.threadIdentifier = threadIdentifier(for: phase, uniqueId: uniqueId)
        applyInterruptionLevel(to: content, phase: phase, timeSensitive: timeSensitive)
        return content
    }

    func threadIdentifier(for phase: PomodoroPhase, uniqueId: String) -> String {
        if UIApplication.shared.applicationState == .active {
            return id(for: phase)
        }
        return uniqueId
    }

    func applyInterruptionLevel(
        to content: UNMutableNotificationContent,
        phase: PomodoroPhase,
        timeSensitive: Bool
    ) {
        if #available(iOS 15.0, *) {
            content.interruptionLevel = timeSensitive ? .timeSensitive : .active
        }
    }

    func makeNotificationTrigger(for targetEndAt: Date) -> UNNotificationTrigger {
        let delta = max(0.0, targetEndAt.timeIntervalSince(Date()))
        // 近接（<= 1h）は TimeInterval を使う
        if delta <= 3600 {
            let interval = max(1, ceil(delta))
            return UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        }
        var components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: targetEndAt
        )
        components.second = (components.second ?? 0)
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    }

    func submitNotification(
        id uniqueId: String,
        content: UNMutableNotificationContent,
        trigger: UNNotificationTrigger,
        phase: PomodoroPhase
    ) {
        let request = UNNotificationRequest(
            identifier: uniqueId,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { _ in }
        lastIssuedIdForPhase[phase] = uniqueId
    }

    /// 内部: 即時通知作成
    func schedule(for phase: PomodoroPhase) {
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
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request) { _ in }
    }
}

// MARK: - Cleanup Helpers

extension NotificationManager {
    /// 対象プリフィクスの pending をすべて削除
    func removePendingForPrefix(_ prefix: String) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map { $0.identifier }.filter { $0.hasPrefix(prefix) }
        if !ids.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    /// 同フェーズの古い delivered のみを予約直前に整理
    func clearDeliveredSamePhaseOnly(forIncomingId incomingId: String, phase: PomodoroPhase) {
        let samePrefix = self.id(for: phase)
        UNUserNotificationCenter.current().getDeliveredNotifications { notes in
            let targets = notes
                .map { $0.request.identifier }
                .filter { $0.hasPrefix(samePrefix) && $0 != incomingId }
            if !targets.isEmpty {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: targets)
            }
        }
    }

    /// 前フェーズの delivered のみを整理
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
}
