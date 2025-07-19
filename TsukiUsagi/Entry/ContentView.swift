import SwiftUI
import Foundation

// MARK: - PreferenceKey for Landscape Detection

struct LandscapePreferenceKey: PreferenceKey {
    static let defaultValue: Bool = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

struct ContentView: View {
    // Environment
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var timerVM: TimerViewModel
    @EnvironmentObject private var sessionManagerV2: SessionManagerV2

    // Environment for Orientation and Accessibility
    @Environment(\.horizontalSizeClass) private var horizontalClass
    @Environment(\.verticalSizeClass) private var verticalClass
    @Environment(\.sizeCategory) private var sizeCategory

    // State
    @State private var showingSettings = false
    @State private var showingEditRecord = false
    @State private var showDiamondStars = false
    @State private var cachedIsLandscape: Bool = false
    @FocusState private var isQuietMoonFocused: Bool

    private let moonTitle = "Centered"

    // UI Const
    private let buttonWidth: CGFloat = 120
    private let buttonHeight: CGFloat = AppConstants.footerBarHeight

    // 比率定数
    private let timerBottomRatio: CGFloat = 1.1 // 画面高に対する TimerPanel の比率
    private let moonPortraitYOffsetRatio: CGFloat = 0.15 // portrait（縦画面）時のmoonは少し上げる
    private let moonLandscapeYOffsetRatio: CGFloat = 0.1 // landscape（横画面）時のmoonは少し上げる

    // 星の数
    private let flowingStarCount: Int = 70
    private let staticStarCount: Int = 40

    // MARK: - Computed Properties

    /// より正確な向き判定（iPad Split View対応）
    private func safeIsLandscape(size: CGSize) -> Bool {
        guard size.width > 0, size.height > 0 else { return false }
        return horizontalClass == .regular ||
            (size.width > size.height && size.width > 600)
    }

    /// デバイス別のマージン調整
    private var landscapeMargin: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 40 // iPad は余裕を持たせる
        } else {
            return 20 // iPhone はコンパクトに
        }
    }

    /// Dynamic Type対応のフォントサイズ調整
    private var adjustedFontSize: CGFloat {
        switch sizeCategory {
        case .accessibilityExtraExtraExtraLarge:
            return 14
        case .accessibilityExtraExtraLarge:
            return 16
        case .accessibilityExtraLarge:
            return 18
        default:
            return 20
        }
    }

    /// 向き変更の最適化
    private func updateOrientation(size: CGSize) {
        let newIsLandscape = safeIsLandscape(size: size)
        if cachedIsLandscape != newIsLandscape {
            cachedIsLandscape = newIsLandscape
        }
    }

    /// Gearボタン共通アクション
    private func gearButtonAction(showing: inout Bool) {
        HapticManager.shared.buttonTapFeedback()
        showing = true
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let size = geo.size
                let safeAreaInsets = geo.safeAreaInsets
                let isLandscape = safeIsLandscape(size: size)

                if size.width > 0 && size.height > 0 {
                    ZStack(alignment: .bottom) {
                        // 背景レイヤ
                        BackgroundGradientView().ignoresSafeArea()
                        AwakeEnablerView(hidden: true)
                        StaticStarsView(starCount: staticStarCount)

                        // FlowingStarsViewなどの星エフェクトはタイマー進行中のみ
                        if !timerVM.isSessionFinished {
                            FlowingStarsView(
                                starCount: flowingStarCount,
                                angle: .degrees(90), // 下向き
                                durationRange: 24 ... 40,
                                sizeRange: 2 ... 4,
                                spawnArea: nil
                            )
                            FlowingStarsView(
                                starCount: flowingStarCount,
                                angle: .degrees(-90), // 上向き
                                durationRange: 24 ... 40,
                                sizeRange: 2 ... 4,
                                spawnArea: nil
                            )
                        }

                        // Moon+Timerセット or QuietMoonView
                        MainPanel(
                            size: size,
                            safeAreaInsets: safeAreaInsets,
                            isLandscape: isLandscape,
                            timerVM: timerVM,
                            moonTitle: moonTitle,
                            landscapeMargin: landscapeMargin,
                            moonPortraitYOffsetRatio: moonPortraitYOffsetRatio,
                            moonLandscapeYOffsetRatio: moonLandscapeYOffsetRatio,
                            isQuietMoonFocused: $isQuietMoonFocused,
                            showingEditRecord: $showingEditRecord
                        )
                        .onPreferenceChange(LandscapePreferenceKey.self) { _ in
                            updateOrientation(size: size)
                        }

                        // footerBarはZStackの一番下
                        FooterBar(
                            buttonHeight: buttonHeight,
                            buttonWidth: buttonWidth,
                            dateString: DateFormatters.displayDateNoYear.string(from: Date()),
                            onGearTap: { gearButtonAction(showing: &showingSettings) },
                            startPauseButton: AnyView(startPauseButton())
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, safeAreaInsets.bottom)
                        .zIndex(AppConstants.footerZIndex)

                        // RecordedTimesViewを縦画面時のみfooterBarの直上に追加
                        if timerVM.isSessionFinished && !timerVM.isWorkSession && !isLandscape {
                            RecordedTimesView(
                                formattedStartTime: timerVM.formattedStartTime,
                                formattedEndTime: timerVM.formattedEndTime,
                                actualSessionMinutes: timerVM.actualSessionMinutes,
                                onEdit: { showingEditRecord = true }
                            )
                            .sessionVisibility(isVisible: timerVM.isSessionFinished)
                            .padding(.bottom, AppConstants.footerBarHeight +
                                    safeAreaInsets.bottom + AppConstants.recordedTimesBottomSpacing)
                            .zIndex(AppConstants.overlayZIndex)
                            .sessionEndTransition(timerVM)
                        }

                        // ダイヤモンドスター
                        if showDiamondStars {
                            DiamondStarsOnceView {
                                showDiamondStars = false
                            }
                            .allowsHitTesting(false)
                        }
                    }
                    .ignoresSafeArea()
                    .onReceive(timerVM.$flashStars.dropFirst()) { _ in
                        showDiamondStars = true
                    }
                    .sheet(isPresented: $showingSettings) {
                        SettingsView(size: size, safeAreaInsets: safeAreaInsets)
                            .environmentObject(timerVM)
                            .environmentObject(historyVM)
                            .environmentObject(sessionManagerV2)
                    }
                    .sheet(isPresented: $showingEditRecord) {
                        TimerEditView()
                            .environmentObject(timerVM)
                            .environmentObject(historyVM)
                            .environmentObject(sessionManagerV2)
                    }
                    .onChange(of: timerVM.isSessionFinished) { _, newValue in
                        if newValue {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isQuietMoonFocused = true
                            }
                        }
                    }
                    // デバッグ用の状態変化追跡
                    .onReceive(timerVM.$isSessionFinished) { _ in
                        // print("ContentView: isSessionFinished changed to \(isFinished)")
                    }
                    .onReceive(timerVM.$isWorkSession) { _ in
                        // print("ContentView: isWorkSession changed to \(isWork)")
                    }
                    .onReceive(timerVM.$isRunning) { _ in
                        // print("ContentView: isRunning changed to \(isRunning)")
                    }
                    .animation(
                        .easeInOut(duration: 0.3)
                            .delay(0.1),
                        value: isLandscape
                    )
                }
            }
        }
        .environmentObject(sessionManagerV2)
    }

    // MARK: - Start / Pause Button

    private func startPauseButton() -> some View {
        Button(timerVM.isRunning ? "PAUSE" : "START") {
            HapticManager.shared.buttonTapFeedback()
            if timerVM.isRunning {
                timerVM.stopTimer()
            } else {
                // セッション完了後の再スタート時は設定値を使用
                let secondsToStart = timerVM.isSessionFinished ? timerVM.workLengthMinutes * 60 : timerVM.timeRemaining
                timerVM.startTimer(seconds: secondsToStart)
            }
        }
        .frame(width: buttonWidth, height: buttonHeight)
        .background(Color.white.opacity(0.2),
                    in: RoundedRectangle(cornerRadius: 20))
        .titleWhiteAvenir(weight: .bold)
        .foregroundColor(.white)
    }

    // MARK: - Helper Methods

    private func roundedSize(_ size: CGSize) -> CGSize {
        return CGSize(
            width: round(size.width),
            height: round(size.height)
        )
    }
}

// --- Preview用ダミークラス（ファイルスコープに移動） ---
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
private class DummyNotification: PhaseNotificationServiceable {
    func sendStartNotification() {}
    func cancelNotification() {}
    func scheduleSessionEndNotification(after seconds: Int, phase: PomodoroPhase) {}
    func sendPhaseChangeNotification(for phase: PomodoroPhase) {}
    func cancelSessionEndNotification() {}
    func finalizeWorkPhase() {}
    func finalizeBreakPhase() {}
}
private class DummyHaptic: HapticServiceable {
    func heavyImpact() {}
    func lightImpact() {}
}
private class DummyHistory: SessionHistoryServiceable {
    func add(parameters: AddSessionParameters) {}
}
private class DummyPersistence: TimerPersistenceManageable {
    var timeRemaining: Int = 0
    var isRunning: Bool = false
    var isWorkSession: Bool = true
    func saveTimerState() {}
    func restoreTimerState() {}
}
private class DummyFormatter: TimeFormatterUtilable {
    func format(seconds: Int) -> String { "00:00" }
    func format(date: Date?) -> String { "date" }
}

#Preview {
    let history = HistoryViewModel()
    let timer = TimerViewModel(
        engine: DummyEngine(),
        notificationService: DummyNotification(),
        hapticService: DummyHaptic(),
        historyService: DummyHistory(),
        persistenceManager: DummyPersistence(),
        formatter: DummyFormatter()
    )
    let sessionManagerV2 = SessionManagerV2()
    ContentView()
        .environmentObject(history)
        .environmentObject(timer)
        .environmentObject(sessionManagerV2)
}
