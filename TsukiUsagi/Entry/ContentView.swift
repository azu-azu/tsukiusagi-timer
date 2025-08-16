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
    @State private var showingSideMenu = false
    @State private var showingEditRecord = false
    @State private var showDiamondStars = false
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

    /// 星アニメ可否の単一の真理
    private var shouldAnimateStars: Bool {
        if reduceMotion { return false }
        if showingSideMenu { return false }
        let isInitial = timerVM.timeRemaining == timerVM.workLengthMinutes * 60
        return timerVM.isRunning || isInitial
    }

    /// ハンバーガーメニューボタン共通アクション
    private func hamburgerMenuAction() {
        HapticManager.shared.buttonTapFeedback()
        withAnimation(.easeInOut(duration: 0.3)) {
            showingSideMenu.toggle()
        }
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

                        // セッション未完了かつアニメーション可時に星エフェクト表示
                        if !timerVM.isSessionFinished && shouldAnimateStars {
                            let baseCount = isLowPowerMode ? 24 : flowingStarCount
                            let flowingCount = isLandscape ? Int(Double(baseCount) * 0.7) : baseCount
                            let dur: ClosedRange<Double> = isLandscape ? 28 ... 44 : 24 ... 40
                            FlowingStarsView(
                                starCount: flowingCount,
                                angle: .degrees(90), // 下向き
                                durationRange: dur,
                                sizeRange: 2 ... 4,
                                spawnArea: nil
                            )
                            FlowingStarsView(
                                starCount: flowingCount,
                                angle: .degrees(-90), // 上向き
                                durationRange: dur,
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
                            showingEditRecord: $showingEditRecord,
                            isMoonAnimationActive: shouldAnimateStars
                        )
                        

                        // footerBarはZStackの一番下（ギアボタンと日付を削除）
                        FooterBar(
                            buttonHeight: buttonHeight,
                            buttonWidth: buttonWidth,
                            dateString: "", // 日付表示を削除
                            onGearTap: nil, // ギアボタンを無効化
                            startPauseButton: startPauseButton()
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, safeAreaInsets.bottom)
                        .zIndex(AppConstants.footerZIndex)

                        // ギアボタン（左下）と日付表示（右下）
                        VStack {
                            Spacer()
                            HStack {
                                // ギアボタン（左下）
                                HamburgerMenuButton(action: hamburgerMenuAction)
                                    .padding(.leading, 16)
                                    .padding(.bottom, safeAreaInsets.bottom)

                                Spacer()
                                // 日付表示（右下）
                                Text(DateFormatters.displayDateNoYear.string(from: today))
                                    .font(DesignTokens.Fonts.footerDate)
                                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                                    .padding(.trailing, 16)
                                    .padding(.bottom, safeAreaInsets.bottom)
                            }
                        }
                        .zIndex(2001) // サイドメニューより下にしたいならOK（上にしたいならSideMenuをより大きく）

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
                    .onReceive(timerVM.$flashStars.dropFirst()) { _ in
                        showDiamondStars = true
                    }
                    .sheet(isPresented: $showingEditRecord) {
                        TimerEditView()
                    }
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
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                        today = Date()
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
        .foregroundColor(DesignTokens.PureColors.textWhite)
    }

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
