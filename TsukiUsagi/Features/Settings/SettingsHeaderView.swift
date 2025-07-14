import SwiftUI

struct SettingsHeaderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var timerVM: TimerViewModel
    @AppStorage("activityLabel") private var activityLabel: String = "Work"

    // 親Viewから渡されるdismiss関数
    var onDismiss: (() -> Void)?

    // ヘッダー周りのpadding
    private let headerTopPadding: CGFloat = 18
    private let headerBottomPadding: CGFloat = 20

    private var isCustomActivity: Bool {
        !["Work", "Study", "Read"].contains(activityLabel)
    }

    // バリデーション関数の共通化
    private func isActivityEmpty() -> Bool {
        return activityLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func shouldDisableDone() -> Bool {
        return isCustomActivity && isActivityEmpty()
    }

    var body: some View {
        HStack {
            Button("Close") {
                onDismiss?() ?? dismiss()
            }
            .foregroundColor(DesignTokens.Colors.moonTextSecondary)

            Spacer()

            Button("Done") {
                // 設定変更を反映
                timerVM.refreshAfterSettingsChange()
                onDismiss?() ?? dismiss()
            }
            .disabled(shouldDisableDone())
            .foregroundColor(
                shouldDisableDone()
                    ? .gray
                    : DesignTokens.Colors.moonAccentBlue
            )
        }
        .padding(.horizontal)
        .padding(.top, headerTopPadding)
        .padding(.bottom, headerBottomPadding)
    }
}

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
#endif
