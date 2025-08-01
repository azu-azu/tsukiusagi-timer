import SwiftUI

struct SideMenuDurationView: View {
    @AppStorage("workMinutes") private var workMinutes: Int = 25
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5
    @AppStorage("activityLabel") private var activityLabel: String = "Work"

    @EnvironmentObject private var timerVM: TimerViewModel
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var sessionManager: SessionManager

    @Binding var isPresented: Bool

    // workMinutesの選択肢: 1, 3, 5, 10, 15, ... 60
    private let workMinutesOptions: [Int] = [1, 3, 5] + Array(stride(from: 10, through: 60, by: 5))

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // セクションタイトル
            Text("Timer Settings")
                .font(DesignTokens.Fonts.labelBold)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)

            // Work Duration
            SideMenuDurationRowView(
                title: "Work",
                value: $workMinutes,
                options: workMinutesOptions,
                decrementAction: {
                    let currentIndex = workMinutesOptions.firstIndex(of: workMinutes) ?? 0
                    if currentIndex > 0 {
                        workMinutes = workMinutesOptions[currentIndex - 1]
                    }
                },
                incrementAction: {
                    let currentIndex = workMinutesOptions.firstIndex(of: workMinutes) ?? 0
                    if currentIndex < workMinutesOptions.count - 1 {
                        workMinutes = workMinutesOptions[currentIndex + 1]
                    }
                }
            )

            // Break Duration
            SideMenuDurationRowView(
                title: "Break",
                value: $breakMinutes,
                options: nil,
                decrementAction: {
                    if breakMinutes > 1 { breakMinutes -= 1 }
                },
                incrementAction: {
                    if breakMinutes < 30 { breakMinutes += 1 }
                }
            )

            // Session種類編集リンク
            NavigationLink(destination: DurationSessionSettingsView()
                .environmentObject(timerVM)
                .environmentObject(historyVM)
                .environmentObject(sessionManager)
            ) {
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

                    Image(systemName: "chevron.right")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textMuted)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(TapGesture().onEnded {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
            })
        }
        .padding(.vertical, 8)
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

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
                .frame(minWidth: minWidth, alignment: .leading)

            Spacer()

            // 時間の+/-ボタンと値表示
            HStack(spacing: buttonSpacing) {
                durationButton(systemName: "minus", action: decrementAction)

                Text("\(value)")
                    .font(DesignTokens.Fonts.numericLabel)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                    .frame(width: buttonSize, alignment: .center)

                durationButton(systemName: "plus", action: incrementAction)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)

        // 各Rowに色をつける
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.black.opacity(0.8))
        )
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
