import SwiftUI

struct ResetStopSectionView: View {
    @EnvironmentObject private var timerVM: TimerViewModel
    @Environment(\.dismiss) private var dismiss

    private let cardCornerRadius: CGFloat = 8

    var body: some View {
        section(title: "", isCompact: false) {
            VStack(spacing: 14) {
                Button {
                    timerVM.resetTimer()
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        // 🛑 Reset
                        Image(systemName: "arrow.uturn.backward")
                        Text(timerVM.isWorkSession
                            ? "Reset Timer (No Save)"
                            : "Reset Timer (already saved)"
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .tint(.red.opacity(0.8))

                // 🛑 Stop
                if timerVM.canForceFinish {
                    Button {
                        timerVM.forceFinishWorkSession()
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "forward.end")
                            Text("Stop (Save)")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .tint(.blue)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "forward.end")
                            .foregroundColor(.gray.opacity(0.6))
                        Text("Stop (Save)")
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .debugSection(String(describing: Self.self), position: .topLeading)
    }

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        isCompact: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: isCompact
                ? DesignTokens.Spacing.extraSmall
                : DesignTokens.Spacing.small
        ) {
            if !title.isEmpty {
                Text(title)
                    .font(DesignTokens.Fonts.sectionTitle)
                    .foregroundColor(DesignTokens.Colors.moonTextSecondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(isCompact
                ? EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
                : EdgeInsets())
            .padding(isCompact ? .init() : .all)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .fill(DesignTokens.Colors.cosmosCardBG)
            )
        }
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
            func sendPhaseChangeNotification(for phase: PomodoroPhase) {}
            func cancelSessionEndNotification() {}
            func finalizeWorkPhase() {}
            func finalizeBreakPhase() {}
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
            func saveTimerState() {}
            func restoreTimerState() {}
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
