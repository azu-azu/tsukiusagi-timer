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

    // 内部: 通知作成
    private func schedule(for phase: PomodoroPhase) {
        let content = UNMutableNotificationContent()

        switch phase {
        case .focus:
            content.title = "Focus Again!"
            content.body  = "そろそろ集中モードにもどろか 🌕"
        case .breakTime:
            content.title = "Break Time!"
            content.body  = "おつかれさま。少し休憩しよか ☕️"
        }

        content.sound = .default
        let trigger  = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request  = UNNotificationRequest(identifier: UUID().uuidString,
                                             content: content,
                                             trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知送信失敗: \(error.localizedDescription)")
            } else {
                print("通知送信成功")
            }
        }
    }
}
