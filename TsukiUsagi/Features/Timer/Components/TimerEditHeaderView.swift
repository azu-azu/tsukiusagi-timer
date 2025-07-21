import SwiftUI

// MARK: - TimerEdit用のヘッダービュー
struct TimerEditHeaderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var timerVM: TimerViewModel

    // TimerEditViewから渡される編集中の値
    let editedActivity: String
    let editedSubtitle: String
    let editedMemo: String
    let editedEnd: Date

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
        CommonHeaderView(
            configuration: .cancelSave(
                title: "Edit Record",
                dismiss: dismiss,
                onSave: {
                    historyVM.updateLast(
                        activity: editedActivity,
                        subtitle: editedSubtitle,
                        memo: editedMemo,
                        end: editedEnd
                    )
                    timerVM.setEndTime(editedEnd)
                    dismiss()
                },
                isSaveDisabled: shouldDisableSave()
            )
        )
    }
}

// MARK: - プレビュー
#if DEBUG
struct TimerEditHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        TimerEditHeaderView(
            editedActivity: "Work",
            editedSubtitle: "Test subtitle",
            editedMemo: "Test memo",
            editedEnd: Date()
        )
        .environmentObject(HistoryViewModel())
        .environmentObject(TimerViewModel(
            engine: DummyEngine(),
            notificationService: DummyNotificationService(),
            hapticService: DummyHapticService(),
            historyService: DummyHistoryService(),
            persistenceManager: DummyPersistenceManager(),
            formatter: DummyFormatter()
        ))
        .background(Color.cosmosBackground)
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
    func sendPhaseChangeNotification(for phase: PomodoroPhase) {}
    func cancelSessionEndNotification() {}
    func finalizeWorkPhase() {}
    func finalizeBreakPhase() {}
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
    func saveTimerState() {}
    func restoreTimerState() {}
}

private class DummyFormatter: TimeFormatterUtilable {
    func format(seconds: Int) -> String { return "" }
    func format(date: Date?) -> String { return "" }
}

private class HistoryViewModel: ObservableObject {
    func updateLast(activity: String, subtitle: String, memo: String, end: Date) {}
}
#endif
