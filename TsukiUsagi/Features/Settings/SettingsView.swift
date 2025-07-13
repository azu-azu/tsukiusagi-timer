import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var timerVM: TimerViewModel
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var sessionManagerV2: SessionManagerV2
    @Environment(\.horizontalSizeClass) private var horizontalClass
    @Environment(\.verticalSizeClass) private var verticalClass
    @Environment(\.dismiss) private var dismiss

    @AppStorage("activityLabel") private var activityLabel: String = "Work"
    @AppStorage("subtitleLabel") private var subtitleLabel: String = ""

    @FocusState private var isActivityFocused: Bool
    @FocusState private var isSubtitleFocused: Bool
    @FocusState private var dummyMemoFocused: Bool

    private let betweenCardSpaceNarrow: CGFloat = 4
    private let betweenCardSpace: CGFloat = 24
    private let breakBottomPadding: CGFloat = 26
    private let labelCornerRadius: CGFloat = 6
    private let clipRadius: CGFloat = 30 // 画面全体のコーナー
    private let flowingStarCount: Int = 20

    let size: CGSize
    let safeAreaInsets: EdgeInsets

    // リアルタイムでエラー状態を計算
    private var currentShowEmptyError: Bool {
        let isCustomActivity = !["Work", "Study", "Read"].contains(activityLabel)
        return isCustomActivity && activityLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        SettingsHeaderView(onDismiss: { dismiss() })

                        WorkTimeSectionView()
                            .padding(.bottom, betweenCardSpaceNarrow)

                        BreakTimeSectionView()
                            .padding(.bottom, breakBottomPadding)

                        sessionLabelSection()
                            .padding(.bottom, betweenCardSpaceNarrow)

                        ManageSessionNamesSectionView()
                            .padding(.bottom, betweenCardSpace)

                        ResetStopSectionView()
                            .padding(.bottom, betweenCardSpace)

                        ViewHistorySectionView()
                            .padding(.bottom, betweenCardSpace)
                    }
                    .padding()
                }
                .background(
                    ZStack {
                        Color.moonBackground.ignoresSafeArea()
                        StaticStarsView(starCount: 30).allowsHitTesting(false)
                        FlowingStarsView(
                            starCount: flowingStarCount,
                            angle: .degrees(135),
                            durationRange: 24 ... 40,
                            sizeRange: 2 ... 4,
                            spawnArea: nil
                        )
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: clipRadius))
            }
            .modifier(DismissKeyboardOnTap(
                isActivityFocused: $isActivityFocused,
                isSubtitleFocused: $isSubtitleFocused,
                isMemoFocused: $dummyMemoFocused
            ))
        }
    }

    private func sessionLabelSection() -> some View {
        VStack(
            alignment: .leading,
            spacing: DesignTokens.Spacing.small
        ) {
            Text("Session Label")
                .font(DesignTokens.Fonts.sectionTitle)
                .foregroundColor(DesignTokens.Colors.moonTextSecondary)

            VStack(alignment: .leading, spacing: 10) {
                SessionLabelSection(
                    activity: $activityLabel,
                    subtitle: $subtitleLabel,
                    isActivityFocused: $isActivityFocused,
                    isSubtitleFocused: $isSubtitleFocused,
                    labelCornerRadius: labelCornerRadius,
                    showEmptyError: .constant(currentShowEmptyError),
                    onDone: nil
                )
            }
            .padding(.all)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignTokens.Colors.moonCardBG)
            )
        }
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct DismissKeyboardOnTap: ViewModifier {
    var isActivityFocused: FocusState<Bool>.Binding
    var isSubtitleFocused: FocusState<Bool>.Binding
    var isMemoFocused: FocusState<Bool>.Binding

    func body(content: Content) -> some View {
        content.onTapGesture {
            UIApplication.shared.endEditing()
            isActivityFocused.wrappedValue = false
            isSubtitleFocused.wrappedValue = false
            isMemoFocused.wrappedValue = false
        }
    }
}

// 横画面判定用ユーティリティ
private func safeIsLandscape(
    size: CGSize,
    horizontalClass: UserInterfaceSizeClass?,
    verticalClass _: UserInterfaceSizeClass?
) -> Bool {
    return horizontalClass == .regular || size.width > size.height
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
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
        return SettingsView(size: .init(width: 375, height: 812), safeAreaInsets: .init())
            .environmentObject(TimerViewModel(
                engine: DummyEngine(),
                notificationService: DummyNotification(),
                hapticService: DummyHaptic(),
                historyService: DummyHistory(),
                persistenceManager: DummyPersistence(),
                formatter: DummyFormatter()
            ))
            .environmentObject(HistoryViewModel())
            .environmentObject(SessionManager())
            .environmentObject(SessionManagerV2())
    }
}
#endif
