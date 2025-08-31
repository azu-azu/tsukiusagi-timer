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
    private var breakEndAt: Date?
    private var breakTimer: Timer?

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
        if sendNotification {
            NotificationManager.shared.sendPhaseChangeNotification(for: .breakTime)
        }

        isSessionFinished = true
        isWorkSession = false // ← ブレイクモードへ

        // 休憩終了の絶対時刻を確定
        breakEndAt = Date().addingTimeInterval(TimeInterval(breakMinutes * 60))

        // 既存の休憩通知をキャンセル→1本だけ再予約（多重予約防止）
        NotificationManager.shared.cancelSessionEndNotification()
        NotificationManager.shared.scheduleSessionEndNotification(
            after: breakMinutes * 60,
            phase: .breakTime
        )

        // 隠し休憩タイマー（.common、毎tick差分再計算）
        breakTimer?.invalidate()
        breakTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self, let end = self.breakEndAt else { return }
            let remain = Int(ceil(end.timeIntervalSinceNow))
            if remain <= 0 {
                self.breakTimer?.invalidate()
                self.breakTimer = nil
                Task { @MainActor in self.finalizeBreak(sendNotification: sendNotification) }
            }
        }
        if let t = breakTimer { RunLoop.main.add(t, forMode: .common); t.tolerance = 0.1 }
    }

    /// 休憩終了後に呼ぶまとめ関数
    private func finalizeBreak(sendNotification: Bool = true) {
        if sendNotification {
            NotificationManager.shared.sendPhaseChangeNotification(for: .focus)
        }
        // 状態は何も変更しない
        breakTimer?.invalidate(); breakTimer = nil
        breakEndAt = nil
        // 休憩関連の終了通知はここでキャンセル（保険）
        NotificationManager.shared.cancelSessionEndNotification()
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
    func forceFinishWorkSession() {
        // 履歴保存は呼び出し側で行う
        isSessionFinished = true
        isWorkSession = false
        breakTimer?.invalidate(); breakTimer = nil
        breakEndAt = nil
        NotificationManager.shared.cancelSessionEndNotification()
    }

    deinit {
        breakTimer?.invalidate(); breakTimer = nil
    }

    // 公開getter
    public var currentActivityLabel: String { activityLabel }
    public var currentSubtitleLabel: String { subtitleLabel }
}
