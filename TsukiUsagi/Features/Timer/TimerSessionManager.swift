import Foundation
import SwiftUI

/// セッション管理を担当するManager
final class TimerSessionManager: ObservableObject {
    @Published var isWorkSession: Bool = true
    @Published var isSessionFinished = false

    // User-configurable
    @AppStorage("activityLabel") private var activityLabel: String = "Work"
    @AppStorage("subtitleLabel") private var subtitleLabel: String = ""
    @AppStorage("workMinutes") private var workMinutes: Int = 25
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5

    private let historyVM: HistoryViewModel

    init(historyVM: HistoryViewModel) {
        self.historyVM = historyVM
    }

    /// セッション完了処理
    @MainActor
    func sessionCompleted(sendNotification: Bool = true) async {
        // セッション終了時刻を記録（既にセットされていれば上書きしない）
        // 履歴に本フェーズを保存
        // フェーズ別後処理
        if isWorkSession {
            finalizeWork(sendNotification: sendNotification)
        } else {
            finalizeBreak(sendNotification: sendNotification)
        }
    }

    /// Work終了後に呼ぶまとめ関数
    private func finalizeWork(sendNotification: Bool = true) {
        HapticManager.shared.heavyImpact()
        if sendNotification {
            NotificationManager.shared.sendPhaseChangeNotification(for: .breakTime)
        }

        isSessionFinished = true
        isWorkSession = false // ← ブレイクモードへ

        // 休憩タイマーを"見えないまま"走らせる
        var secondsLeft = breakMinutes * 60 // 表示は更新しない
        print("📝 secondsLeft  =", secondsLeft)
        Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { [weak self] t in
            guard let self else { return }
            secondsLeft -= 1
            if secondsLeft <= 0 {
                t.invalidate()
                self.finalizeBreak(sendNotification: sendNotification)
            }
        }
    }

    /// 休憩終了後に呼ぶまとめ関数
    private func finalizeBreak(sendNotification: Bool = true) {
        HapticManager.shared.heavyImpact()
        if sendNotification {
            NotificationManager.shared.sendPhaseChangeNotification(for: .focus)
        }
        // 状態は何も変更しない
    }

    /// 履歴にセッションを追加
    @MainActor
    func addSessionToHistory(start: Date, end: Date, phase: PomodoroPhase) {
        let parameters = AddSessionParameters(
            start: start,
            end: end,
            phase: phase,
            activity: activityLabel,
            subtitle: subtitleLabel,
            memo: nil
        )
        historyVM.add(parameters: parameters)
    }

    /// 強制終了（Stopボタン用）
    func forceFinishWorkSession() async {
        // 履歴保存は呼び出し側で行う
        isSessionFinished = true
        isWorkSession = false
    }

    // 公開getter
    public var currentActivityLabel: String { activityLabel }
    public var currentSubtitleLabel: String { subtitleLabel }
}