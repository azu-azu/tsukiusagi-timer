import SwiftUI

// MARK: - TimerEdit用のヘッダービュー
struct TimerEditHeaderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var timerVM: TimerViewModel

    // TimerEditViewから渡される編集中の値
    let editedActivity: String
    let editedTask: String
    let editedMemo: String
    let editedEnd: Date
    let isSaveDisabledExtra: Bool

    private var isCustomActivity: Bool {
        let predefinedActivities = ["Work", "Study", "Read"]
        return !predefinedActivities.contains { $0.lowercased() == editedActivity.lowercased() }
    }

    private func isActivityEmpty() -> Bool {
        return editedActivity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func shouldDisableSave() -> Bool {
        return isCustomActivity && isActivityEmpty()
    }

    var body: some View {
        VStack(spacing: 8) {
            CommonHeaderView(
                configuration: .cancelSave(
                    title: NSLocalizedString("timer_edit_record_title", comment: "Edit record title"),
                    dismiss: dismiss,
                    onSave: {
                        historyVM.updateLast(
                            sessionName: editedActivity,
                            task: editedTask,
                            memo: editedMemo,
                            end: editedEnd
                        )
                        // UI即時反映（Quiet Moon / RecordedTimesView）
                        timerVM.applyEditedEndTime(editedEnd)
                        // 保存完了通知を投げて、呼び出し側で閉じる＋HUD表示などを行う
                        NotificationCenter.default.post(name: Notification.Name("TimerEditSaved"), object: nil)
                    },
                    isSaveDisabled: shouldDisableSave() || isSaveDisabledExtra
                )
            )

            // 明示的な Reset アクション（自動スクロール/自動戻しは廃止）
            HStack {
                Spacer()
                Button {
                    NotificationCenter.default.post(name: Notification.Name("TimerEditReset"), object: nil)
                } label: {
                    Label(Copy.Button.reset, systemImage: "arrow.uturn.left")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.bordered)
                .tint(.gray)
                .accessibilityIdentifier("resetEditedRecordButton")
                .accessibilityLabel(NSLocalizedString("timer_edit_reset_a11y", comment: "Reset accessibility label"))
                .accessibilityHint(NSLocalizedString("timer_edit_reset_hint", comment: "Reset accessibility hint"))
            }
            .padding(.horizontal)
        }
        .debugComponent("TimerEditHeaderView", position: .topLeading)
    }
}

// MARK: - プレビュー
#if DEBUG
struct TimerEditHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        TimerEditHeaderView(
            editedActivity: "Work",
            editedTask: "Test task",
            editedMemo: "Test memo",
            editedEnd: Date(),
            isSaveDisabledExtra: false
        )
        .environmentObject(DummyHistoryViewModel())
        .environmentObject(TimerViewModel(
            engine: DummyEngine(),
            notificationService: DummyNotificationService(),
            hapticService: DummyHapticService(),
            historyService: DummyHistoryService(),
            persistenceManager: DummyPersistenceManager(),
            formatter: DummyFormatter()
        ))
        .background(DesignTokens.CosmosColors.background)
    }
}

// ダミーサービス（プレビュー用）
private class DummyEngine: TimerEngineable {
    var timeRemaining: Int = 0
    var isRunning: Bool = false
    var onTick: ((Int) -> Void)?
    var onSessionCompleted: ((TimerSessionInfo) -> Void)?
    func start(seconds: Int) {}
    func pause() {}
    func resume() {}
    func stop() {}
    func reset(to seconds: Int) {}
}

private class DummyNotificationService: PhaseNotificationServiceable {
    func sendStartNotification() {}
    func cancelNotification() {}
    func scheduleSessionEndNotification(after seconds: Int, phase: PomodoroPhase) {}
    func scheduleSessionEndNotification(at endAt: Date, phase: PomodoroPhase, timeSensitive: Bool) {}
    func rescheduleEnd(at endAt: Date, phase: PomodoroPhase, timeSensitive: Bool) {}
    func scheduleChainedSessionEnds(workEndAt: Date, breakEndAt: Date, timeSensitive: Bool) {}
    func ensureFocusAt(breakEndAt: Date, timeSensitive: Bool) {}
    func sendPhaseChangeNotification(for phase: PomodoroPhase) {}
    func cancelSessionEndNotification() {}
    func cancelSessionEndAll() {}
    func finalizeWorkPhase() {}
    func finalizeBreakPhase() {}
    func ensureAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) { completion(true) }
}

private class DummyHapticService: HapticServiceable {
    func heavyImpact() {}
    func lightImpact() {}
}

private class DummyHistoryService: SessionHistoryServiceable {
    func add(parameters: AddSessionParameters) {}
}

private class DummyPersistenceManager: TimerPersistenceManageable {
    var timeRemaining: Int = 0
    var isRunning: Bool = false
    var isWorkSession: Bool = true
    var runStateRaw: String?
    var endAtEpoch: Double?
    var remainingAtPause: Int?
    func saveTimerState() {}
    func restoreTimerState() {}
    func initializeWithWorkMinutes(_ minutes: Int) {}
}

private class DummyFormatter: TimeFormatterUtilable {
    func format(seconds: Int) -> String { return "" }
    func format(date: Date?) -> String { return "" }
}

private class DummyHistoryViewModel: ObservableObject {
    func updateLast(sessionName: String, task: String, memo: String, end: Date) {}
}
#endif
