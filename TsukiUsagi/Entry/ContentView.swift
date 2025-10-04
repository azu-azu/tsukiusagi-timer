import SwiftUI
import Foundation

struct ContentView: View {
    // Environment
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var timerVM: TimerViewModel
    @EnvironmentObject private var sessionManager: SessionManager

    // Environment for Orientation and Accessibility
    @Environment(\.horizontalSizeClass) private var horizontalClass
    // verticalClass/sizeCategory は当面未使用のため削除
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // State
    @State fileprivate var showingSideMenu = false
    @State private var showDiamondStars = false
    @State private var showingEditRecord = false
    @FocusState private var isQuietMoonFocused: Bool
    @State private var isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
    @State private var today = Date()
    @State private var showSavedToast = false
    @State private var savedToastWorkItem: DispatchWorkItem?

    private let moonTitle = "Centered"

    // UI Const
    private let buttonWidth: CGFloat = 120
    private let buttonHeight: CGFloat = AppConstants.footerBarHeight

    // 比率定数（未使用を削除）
    private let moonPortraitYOffsetRatio: CGFloat = 0.15 // portrait（縦画面）時のmoonは少し上げる
    private let moonLandscapeYOffsetRatio: CGFloat = 0.1 // landscape（横画面）時のmoonは少し上げる

    // 星の数
    private let flowingStarCount: Int = 70
    private let staticStarCount: Int = 40

    // MARK: - Computed Properties

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let size = geo.size
                let safeAreaInsets = geo.safeAreaInsets
                let isLandscape = safeIsLandscape(size: size, horizontalClass: horizontalClass)

                if size.width > 0 && size.height > 0 {
                    ZStack(alignment: .bottom) {
                        // 背景レイヤ
                        backgroundLayer(params: ContentView.BackgroundLayerParams(
                            size: size,
                            safeAreaInsets: safeAreaInsets,
                            staticStarCount: staticStarCount,
                            flowingStarCount: flowingStarCount,
                            isLowPowerMode: isLowPowerMode,
                            isSessionFinished: timerVM.isSessionFinished,
                            shouldAnimateStars: shouldAnimateStars(
                                reduceMotion: reduceMotion,
                                showingSideMenu: showingSideMenu,
                                timeRemaining: timerVM.timeRemaining,
                                workLengthMinutes: timerVM.workLengthMinutes,
                                isRunning: timerVM.isRunning
                            ),
                            isLandscape: isLandscape
                        ))

                        // Moon+Timerセット or QuietMoonView
                        MainPanel(
                            size: size,
                            safeAreaInsets: safeAreaInsets,
                            isLandscape: isLandscape,
                            moonTitle: moonTitle,
                            landscapeMargin: landscapeMargin(),
                            moonPortraitYOffsetRatio: moonPortraitYOffsetRatio,
                            moonLandscapeYOffsetRatio: moonLandscapeYOffsetRatio,
                            isQuietMoonFocused: $isQuietMoonFocused,
                            showingEditRecord: $showingEditRecord,
                            isMoonAnimationActive: shouldAnimateStars(
                                reduceMotion: reduceMotion,
                                showingSideMenu: showingSideMenu,
                                timeRemaining: timerVM.timeRemaining,
                                workLengthMinutes: timerVM.workLengthMinutes,
                                isRunning: timerVM.isRunning
                            )
                        )

                        // フッターレイヤ
                        footerLayer(params: ContentView.FooterLayerParams(
                            safeAreaInsets: safeAreaInsets,
                            buttonHeight: buttonHeight,
                            buttonWidth: buttonWidth,
                            today: today,
                            isRunning: timerVM.isRunning,
                            isSessionFinished: timerVM.isSessionFinished,
                            showingSideMenu: $showingSideMenu,
                            onPause: { [weak timerVM] in timerVM?.pauseTimer() },
                            onStart: { [weak timerVM] in timerVM?.startTimer() }
                        ))
                        .id("footer-\(timerVM.isRunning)-\(timerVM.isSessionFinished)")
                        .onAppear {
                        }
                        .onChange(of: timerVM.isRunning) { _, _ in
                        }
                        .onChange(of: timerVM.isSessionFinished) { _, _ in
                        }

                        // RecordedTimesViewレイヤ
                        recordedTimesLayer(params: ContentView.RecordedTimesLayerParams(
                            isLandscape: isLandscape,
                            safeAreaInsets: safeAreaInsets,
                            isSessionFinished: timerVM.isSessionFinished,
                            isWorkSession: timerVM.isWorkSession,
                            formattedStartTime: TimeFormatters.formatTime(date: timerVM.startTime),
                            formattedEndTime: TimeFormatters.formatTime(date: timerVM.endTime),
                            actualSessionMinutes: timerVM.actualSessionMinutes,
                            showingEditRecord: $showingEditRecord
                        ))

                        // ダイヤモンドスター
                        if showDiamondStars {
                            DiamondStarsOnceView {
                                showDiamondStars = false
                                // flashStarsをfalseに戻して、次回のアニメーション発火を可能にする
                                timerVM.flashStars = false
                            }
                            .allowsHitTesting(false)
                        }

                        // サイドメニュー
                        SideMenuView(isPresented: $showingSideMenu)
                            .zIndex(2002) // 本当に最前面にする

                        // 保存トースト（Quiet Moon 画面に戻った直後の軽量HUD）
                        if showSavedToast {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(DesignTokens.Fonts.symbolMedium)
                                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                                Text("Saved")
                                    .font(DesignTokens.Fonts.label)
                                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(DesignTokens.CosmosColors.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(DesignTokens.WhiteColors.stroke)
                            )
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                            .padding(.bottom, safeAreaInsets.bottom + AppConstants.footerBarHeight + 16)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .zIndex(3000)
                            .allowsHitTesting(false)
                        }
                    }
                    .ignoresSafeArea()
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                let horizontalAmount = value.translation.width
                                let verticalAmount = abs(value.translation.height)
                                let openThreshold = max(50, geo.size.width * 0.10)
                                let closeThreshold = -openThreshold

                                // 水平方向のスワイプが垂直方向より大きい場合のみ処理
                                if abs(horizontalAmount) > verticalAmount {
                                    if horizontalAmount > openThreshold && !showingSideMenu {
                                        // 左端20pt内からの右向きスワイプでメニューを開く
                                        if value.startLocation.x <= 20 {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                showingSideMenu = true
                                            }
                                        }
                                    } else if horizontalAmount < closeThreshold && showingSideMenu {
                                        // 左向きスワイプでメニューを閉じる
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showingSideMenu = false
                                        }
                                    }
                                }
                            }
                    )
                    .onReceive(timerVM.$flashStars.dropFirst()) { flashStars in
                        if flashStars {
                            showDiamondStars = true
                        }
                    }
                    // シート提示は MainPanel へ移譲
                    .sheet(isPresented: $showingEditRecord) {
                        // 外側（器）と内側（中身）の両方で黒を明示
                        ZStack {
                            DesignTokens.CosmosColors.background.ignoresSafeArea()
                            TimerEditView()
                                .background(DesignTokens.CosmosColors.background.ignoresSafeArea())
                        }
                    }
                    .presentationBackground(DesignTokens.CosmosColors.background)
                    .onChange(of: timerVM.isSessionFinished) { _, newValue in
                        if newValue {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isQuietMoonFocused = true
                            }
                        }
                    }
                    // showingSideMenu の変更のみで十分（shouldAnimateStars が再評価される）
                    // 低電力モードの変更を監視
                    .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
                        isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
                    }
                    // フォアグラウンド復帰で日付を更新
                    .onReceive(
                        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
                    ) { _ in
                        today = Date()
                        timerVM.appWillEnterForeground()
                    }
                    // バックグラウンド移行時の処理
                    .onReceive(
                        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
                    ) { _ in
                        timerVM.appDidEnterBackground()
                    }
                    // 画面常駐時に0時を跨いだら日付を更新
                    .onAppear { scheduleMidnightTick() }
                    // 編集保存完了でHUDを表示
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("TimerEditSaved"))) { _ in
                        // 既存の消去予約をキャンセルして、表示時間をリセット
                        savedToastWorkItem?.cancel()
                        withAnimation(.easeInOut(duration: 0.2)) { showSavedToast = true }
                        let work = DispatchWorkItem {
                            withAnimation(.easeInOut(duration: 0.3)) { showSavedToast = false }
                        }
                        savedToastWorkItem = work
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6, execute: work)
                    }
                    // SessionManagerからのサイドメニュー開きリクエストを監視
                    .onReceive(sessionManager.$shouldOpenSideMenuOnDismiss) { shouldOpen in
                        if shouldOpen {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingSideMenu = true
                            }
                            sessionManager.resetSideMenuRequest()
                        }
                    }
                    .animation(
                        .easeInOut(duration: 0.3)
                            .delay(0.1),
                        value: isLandscape
                    )
                }
            }
        }
    }

    // MARK: - Start / Pause Button

    // MARK: - Helper Methods
}

// MARK: - Midnight tick
private extension ContentView {
    func scheduleMidnightTick() {
        let cal = Calendar.current
        let next = cal.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0, second: 1),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(60)
        let interval = max(0, next.timeIntervalSinceNow)
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            today = Date()
            scheduleMidnightTick()
        }
    }
}

// Dummy* は MockDependencyContainer への統一方針により削除

#if DEBUG
@MainActor
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let mock = MockDependencyContainer()
        return ContentView()
            .environmentObject(mock.historyVM)
            .environmentObject(mock.timerVM)
            .environmentObject(mock.sessionManager)
    }
}
#endif
