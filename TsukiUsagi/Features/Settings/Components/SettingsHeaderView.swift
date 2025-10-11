import SwiftUI

// MARK: - Settings用のヘッダービュー
struct SettingsHeaderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var timerVM: TimerViewModel
    @AppStorage("activityLabel") private var activityLabel: String = "Work"

    var onDismiss: (() -> Void)?

    private var isCustomActivity: Bool {
        !["Work", "Study", "Read"].contains(activityLabel)
    }

    private func isActivityEmpty() -> Bool {
        return activityLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func shouldDisableDone() -> Bool {
        return isCustomActivity && isActivityEmpty()
    }

    var body: some View {
        CommonHeaderView(
            configuration: .closeDone(
                title: "Settings",
                dismiss: dismiss,
                customClose: onDismiss,
                onDone: {
                    timerVM.refreshAfterSettingsChange()
                    onDismiss?() ?? dismiss()
                },
                isDoneDisabled: shouldDisableDone()
            )
        )
    }
}

// MARK: - プレビュー
#if DEBUG
struct SettingsHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsHeaderView()
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
#endif
