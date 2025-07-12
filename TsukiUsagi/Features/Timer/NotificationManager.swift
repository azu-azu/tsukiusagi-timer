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
    private init() {}

    // 権限リクエスト
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error = error {
                    print("通知許可リクエスト失敗: \(error.localizedDescription)")
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
                print("通知は許可されていません"); return
            }
            self?.schedule(for: phase)
        }
    }

    // 指定秒後にセッション終了通知をスケジューリング
    func scheduleSessionEndNotification(after seconds: Int, phase: PomodoroPhase) {
        checkNotificationStatus { allowed in
            guard allowed else { return }
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

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
            // 追加前に同じIDの通知を削除
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["SessionEnd"])
            let request = UNNotificationRequest(
                identifier: "SessionEnd",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }

    // セッション終了通知をキャンセル
    func cancelSessionEndNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["SessionEnd"])
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
                print("通知失敗: \(error.localizedDescription)")
            } else {
                print("通知成功")
            }
        }
    }
}
