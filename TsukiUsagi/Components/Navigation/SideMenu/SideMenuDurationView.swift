import SwiftUI

struct SideMenuDurationView: View {
    @AppStorage("workMinutes") private var workMinutes: Int = 25
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5
    @AppStorage("activityLabel") private var activityLabel: String = "Work"

    @EnvironmentObject private var timerVM: TimerViewModel
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var sessionManager: SessionManager

    @Binding var isPresented: Bool


    private let blockHorizontalPadding: CGFloat = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Work Duration
            SideMenuDurationRowView(
                title: "Work Duration",
                value: $workMinutes,
                options: DurationConstants.workMinutesOptions,
                decrementAction: DurationActions.makeDecrementWorkAction(
                    workMinutes: $workMinutes,
                    options: DurationConstants.workMinutesOptions,
                    timerVM: timerVM
                ),
                incrementAction: DurationActions.makeIncrementWorkAction(
                    workMinutes: $workMinutes,
                    options: DurationConstants.workMinutesOptions,
                    timerVM: timerVM
                )
            )

            // Break Duration
            SideMenuDurationRowView(
                title: "Break Duration",
                value: $breakMinutes,
                options: nil,
                decrementAction: DurationActions.makeDecrementBreakAction(
                    breakMinutes: $breakMinutes,
                    timerVM: timerVM
                ),
                incrementAction: DurationActions.makeIncrementBreakAction(
                    breakMinutes: $breakMinutes,
                    timerVM: timerVM
                )
            )

            // Session種類表示
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center) {
                    Text("Session")
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                        .frame(minWidth: 50, alignment: .leading)

                    Spacer()

                    Text(activityLabel)
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(.vertical, 4)
                .padding(.trailing, blockHorizontalPadding)

                // 鉛筆マークでの編集リンク
                HStack {
                    Spacer()
                    NavigationLink(destination: DurationSessionSettingsView()
                        .environmentObject(timerVM)
                        .environmentObject(historyVM)
                        .environmentObject(sessionManager)
                    ) {
                        Image(systemName: "pencil")
                            .font(DesignTokens.Fonts.caption)
                            .foregroundColor(DesignTokens.MoonColors.textMuted)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Session Control セクション
            Divider()
                .background(DesignTokens.MoonColors.surfaceSecondary)
                .padding(.vertical, 8)

            sessionControlSection()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Session Control Section

    @ViewBuilder
    private func sessionControlSection() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Reset Button (既存のResetStopSectionViewと同じ機能)
            if timerVM.canForceFinish {
                Button {
                    timerVM.resetTimer()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
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
            // Divider()

            // Stop Button (既存のResetStopSectionViewと同じ機能)
            if timerVM.canForceFinish {
                Button {
                    timerVM.forceFinishWorkSession()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
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
                        .foregroundColor(.gray.opacity(0.6))
                    Text("Stop (Save)")
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(.gray.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Side Menu Duration Row Component

struct SideMenuDurationRowView: View {
    let title: String
    @Binding var value: Int
    let options: [Int]? // Work用のオプション配列（Break用はnil）
    let decrementAction: () -> Void
    let incrementAction: () -> Void

    private let minWidth: CGFloat = 50
    private let buttonSize: CGFloat = 24
    private let buttonSpacing: CGFloat = 8
    private let blockHorizontalPadding: CGFloat = 12

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
                .frame(minWidth: minWidth, alignment: .leading)

            Spacer()

            // 時間の+/-ボタンと値表示（黒背景）
            HStack(spacing: buttonSpacing) {
                durationButton(systemName: "minus", action: decrementAction)

                Text("\(value)")
                    .font(DesignTokens.Fonts.numericLabel)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                    .frame(width: buttonSize, alignment: .center)

                durationButton(systemName: "plus", action: incrementAction)
            }
            .padding(.horizontal, blockHorizontalPadding)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(.black.opacity(0.8))
            )
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helper Methods

    @ViewBuilder
    private func durationButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)
                .frame(width: buttonSize, height: buttonSize)
                .background(
                    Circle()
                        .fill(DesignTokens.CosmosColors.cardBackground)
                )
        }
    }
}

#if DEBUG
struct SideMenuDurationView_Previews: PreviewProvider {
    static var previews: some View {
        SideMenuDurationView(isPresented: .constant(true))
            .environmentObject(TimerViewModel(
                engine: SideMenuPreviewDummyEngine(),
                notificationService: SideMenuPreviewDummyNotification(),
                hapticService: SideMenuPreviewDummyHaptic(),
                historyService: SideMenuPreviewDummyHistory(),
                persistenceManager: SideMenuPreviewDummyPersistence(),
                formatter: SideMenuPreviewDummyFormatter()
            ))
            .environmentObject(HistoryViewModel())
            .environmentObject(SessionManager())
            .padding()
            .background(DesignTokens.CosmosColors.background)
    }
}

// Preview用ダミーサービス
private class SideMenuPreviewDummyEngine: TimerEngineable {
    var timeRemaining: Int = 1500
    var isRunning: Bool = false
    var onTick: ((Int) -> Void)?
    var onSessionCompleted: ((TimerSessionInfo) -> Void)?
    func start(seconds: Int) {}
    func pause() {}
    func resume() {}
    func stop() {}
    func reset(to seconds: Int) {}
}

private class SideMenuPreviewDummyNotification: PhaseNotificationServiceable {
    func sendStartNotification() {}
    func cancelNotification() {}
    func scheduleSessionEndNotification(after seconds: Int, phase: PomodoroPhase) {}
    func sendPhaseChangeNotification(for phase: PomodoroPhase) {}
    func cancelSessionEndNotification() {}
    func finalizeWorkPhase() {}
    func finalizeBreakPhase() {}
}

private class SideMenuPreviewDummyHaptic: HapticServiceable {
    func heavyImpact() {}
    func lightImpact() {}
}

private class SideMenuPreviewDummyHistory: SessionHistoryServiceable {
    func add(parameters: AddSessionParameters) {}
}

private class SideMenuPreviewDummyPersistence: TimerPersistenceManageable {
    var timeRemaining: Int = 1500
    var isRunning: Bool = false
    var isWorkSession: Bool = true
    func saveTimerState() {}
    func restoreTimerState() {}
}

private class SideMenuPreviewDummyFormatter: TimeFormatterUtilable {
    func format(seconds: Int) -> String { "25:00" }
    func format(date: Date?) -> String { "2024-01-01" }
}
#endif
