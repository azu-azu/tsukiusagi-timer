import SwiftUI

struct ResetStopSectionView: View {
    @EnvironmentObject private var timerVM: TimerViewModel
    @Environment(\.dismiss) private var dismiss

    private let cardCornerRadius: CGFloat = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
                // 🛑 Reset
                if timerVM.canForceFinish {
                    Button {
                        timerVM.resetTimer(to: timerVM.workMinutes * 60)
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.uturn.backward")
                            Text(timerVM.isWorkSession
                                ? "Reset Timer (No Save)"
                                : "Reset Timer (already saved)"
                            )
                            .font(DesignTokens.Fonts.label)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .tint(DesignTokens.MoonColors.errorBackground)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.uturn.backward")
                            .foregroundColor(DesignTokens.MoonColors.textMuted)
                        Text(timerVM.isWorkSession
                            ? "Reset Timer (No Save)"
                            : "Reset Timer (already saved)"
                        )
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(DesignTokens.MoonColors.textMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // 区切り線
                Divider()

                // 🛑 Stop
                if timerVM.canForceFinish {
                    Button {
                        timerVM.forceFinish()
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "forward.end")
                            Text("Stop (Save)")
                                .font(DesignTokens.Fonts.label)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .tint(DesignTokens.MoonColors.accentBlue)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "forward.end")
                            .foregroundColor(DesignTokens.MoonColors.textMuted)
                        Text("Stop (Save)")
                            .font(DesignTokens.Fonts.label)
                            .foregroundColor(DesignTokens.MoonColors.textMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
        }
        .padding(.all)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DesignTokens.CosmosColors.cardBackground)
        )
        .debugSection(String(describing: Self.self), position: .topLeading)
    }

}

#if DEBUG
struct ResetStopSectionView_Previews: PreviewProvider {
    static var previews: some View {
        // ダミーサービスを用意
        class DummyEngine: TimerEngineable {
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
        class DummyNotification: PhaseNotificationServiceable {
            func sendStartNotification() {}
            func cancelNotification() {}
            func scheduleSessionEndNotification(after seconds: Int, phase: PomodoroPhase) {}
            func scheduleSessionEndNotification(at endAt: Date, phase: PomodoroPhase, timeSensitive: Bool) {}
            func rescheduleEnd(at endAt: Date, phase: PomodoroPhase, timeSensitive: Bool) {}
            func sendPhaseChangeNotification(for phase: PomodoroPhase) {}
            func cancelSessionEndNotification() {}
            func finalizeWorkPhase() {}
            func finalizeBreakPhase() {}
            func ensureAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) { completion(true) }
        }
        class DummyHaptic: HapticServiceable {
            func heavyImpact() {}
            func lightImpact() {}
        }
        class DummyHistory: SessionHistoryServiceable {
            func add(parameters: AddSessionParameters) {}
        }
        class DummyPersistence: TimerPersistenceManageable {
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
        class DummyFormatter: TimeFormatterUtilable {
            func format(seconds: Int) -> String { "00:00" }
            func format(date: Date?) -> String { "date" }
        }
        let vm = TimerViewModel(
            engine: DummyEngine(),
            notificationService: DummyNotification(),
            hapticService: DummyHaptic(),
            historyService: DummyHistory(),
            persistenceManager: DummyPersistence(),
            formatter: DummyFormatter()
        )
        vm._setPreviewState(startTime: Date(), isWorkSession: true, isRunning: true)
        return ResetStopSectionView()
            .environmentObject(vm)
    }
}
#endif
