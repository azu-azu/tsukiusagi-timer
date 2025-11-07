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
    // History save retry UI
    @State private var showHistoryToast = false
    @State private var historyToastMessage = ""
    @State private var historyToastWorkItem: DispatchWorkItem?
    @State private var showHistorySaveBanner = false
    @State private var showSilentCompleteChip = false
    @State private var silentCompleteWorkItem: DispatchWorkItem?
    @State private var recordedTimesNonce = UUID()

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
                let shouldAnimate = shouldAnimateStars(
                    reduceMotion: reduceMotion,
                    showingSideMenu: showingSideMenu,
                    timeRemaining: timerVM.timeRemaining,
                    workLengthMinutes: timerVM.workLengthMinutes,
                    isRunning: timerVM.isRunning
                )

                let context = LayoutContext(
                    size: size,
                    safeAreaInsets: safeAreaInsets,
                    isLandscape: isLandscape,
                    shouldAnimateStars: shouldAnimate
                )

                if context.hasValidSize {
                    mainScene(for: context)
                        .onChange(of: DeepLinkRouter.shared.shouldOpenTimer) { oldValue, shouldOpen in
                            if shouldOpen {
                                // Deep Linkからタイマー画面を開く
                                // 現在はタイマーがメイン画面のため、特別な処理は不要
                                DeepLinkRouter.shared.reset()
                            }
                        }
                }
            }
        }
        .statusBar(hidden: true)
    }

}

// MARK: - Layout helpers
private extension ContentView {
    struct LayoutContext {
        let size: CGSize
        let safeAreaInsets: EdgeInsets
        let isLandscape: Bool
        let shouldAnimateStars: Bool

        var hasValidSize: Bool {
            size.width > 0 && size.height > 0
        }
    }

    func mainScene(for context: LayoutContext) -> some View {
        let base = layoutLayers(for: context)
            .ignoresSafeArea()
            .gesture(sideMenuDragGesture(context: context))
        return applySceneHandlers(to: base, context: context)
    }

    @ViewBuilder
    func layoutLayers(for context: LayoutContext) -> some View {
        let safeAreaInsets = context.safeAreaInsets
        ZStack(alignment: .bottom) {
            backgroundLayer(params: backgroundParams(for: context, safeAreaInsets: safeAreaInsets))
            mainPanel(for: context, safeAreaInsets: safeAreaInsets)
            footerLayerView(for: context, safeAreaInsets: safeAreaInsets)
            recordedTimesView(for: context, safeAreaInsets: safeAreaInsets)
            overlays(for: context, safeAreaInsets: safeAreaInsets)
        }
    }

    @ViewBuilder
    func overlays(for context: LayoutContext, safeAreaInsets: EdgeInsets) -> some View {
        diamondStarsOverlay()
        SideMenuView(isPresented: $showingSideMenu)
            .zIndex(2002)
        savedToast(safeAreaInsets: safeAreaInsets)
        historyToast(safeAreaInsets: safeAreaInsets)
        historySaveBanner(safeAreaInsets: safeAreaInsets)
        silentCompleteChip(safeAreaInsets: safeAreaInsets)
    }

    @ViewBuilder
    func diamondStarsOverlay() -> some View {
        if showDiamondStars {
            DiamondStarsOnceView {
                showDiamondStars = false
                timerVM.flashStars = false
            }
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    func savedToast(safeAreaInsets: EdgeInsets) -> some View {
        if showSavedToast {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(DesignTokens.Fonts.symbolMedium)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                Text("Saved")
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
            }
            .accessibilityIdentifier("savedToast")
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

    @ViewBuilder
    func historyToast(safeAreaInsets: EdgeInsets) -> some View {
        if showHistoryToast {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(DesignTokens.Fonts.symbolMedium)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                Text(historyToastMessage)
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
            }
            .accessibilityIdentifier("historySaveToast")
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DesignTokens.CosmosColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DesignTokens.WhiteColors.stroke)
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            .padding(.bottom, safeAreaInsets.bottom + AppConstants.footerBarHeight + 64)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(3001)
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    func historySaveBanner(safeAreaInsets: EdgeInsets) -> some View {
        if showHistorySaveBanner {
            HStack(spacing: 12) {
                Image(systemName: "icloud.slash")
                    .font(DesignTokens.Fonts.symbolMedium)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Couldn’t save history")
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                    Text("You can retry in background.")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary.opacity(0.8))
                }
                Spacer()
                Button("Retry") {
                    historyVM.retryPendingSave()
                }
                .accessibilityIdentifier("historySaveRetryButton")
                .buttonStyle(.bordered)
            }
            .accessibilityIdentifier("historySaveBanner")
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(DesignTokens.CosmosColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DesignTokens.WhiteColors.stroke)
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            .padding(.bottom, safeAreaInsets.bottom + AppConstants.footerBarHeight + 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(3002)
        }
    }

    @ViewBuilder
    func silentCompleteChip(safeAreaInsets: EdgeInsets) -> some View {
        if showSilentCompleteChip {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(DesignTokens.Fonts.symbolMedium)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                Text("Completed")
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

    func sideMenuDragGesture(context: LayoutContext) -> some Gesture {
        DragGesture()
            .onEnded { value in
                let horizontalAmount = value.translation.width
                let verticalAmount = abs(value.translation.height)
                let openThreshold = max(50, context.size.width * 0.10)
                let closeThreshold = -openThreshold

                if abs(horizontalAmount) > verticalAmount {
                    if horizontalAmount > openThreshold && !showingSideMenu {
                        if value.startLocation.x <= 20 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingSideMenu = true
                            }
                        }
                    } else if horizontalAmount < closeThreshold && showingSideMenu {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingSideMenu = false
                        }
                    }
                }
            }
    }

    func backgroundParams(for context: LayoutContext, safeAreaInsets: EdgeInsets) -> ContentView.BackgroundLayerParams {
        ContentView.BackgroundLayerParams(
            size: context.size,
            safeAreaInsets: safeAreaInsets,
            staticStarCount: staticStarCount,
            flowingStarCount: flowingStarCount,
            isLowPowerMode: isLowPowerMode,
            isSessionFinished: timerVM.isSessionFinished,
            shouldAnimateStars: context.shouldAnimateStars,
            isLandscape: context.isLandscape
        )
    }

    @ViewBuilder
    func mainPanel(for context: LayoutContext, safeAreaInsets: EdgeInsets) -> some View {
        MainPanel(
            size: context.size,
            safeAreaInsets: safeAreaInsets,
            isLandscape: context.isLandscape,
            moonTitle: moonTitle,
            landscapeMargin: landscapeMargin(),
            moonPortraitYOffsetRatio: moonPortraitYOffsetRatio,
            moonLandscapeYOffsetRatio: moonLandscapeYOffsetRatio,
            isQuietMoonFocused: $isQuietMoonFocused,
            showingEditRecord: $showingEditRecord,
            isMoonAnimationActive: context.shouldAnimateStars
        )
    }

    @ViewBuilder
    func footerLayerView(for context: LayoutContext, safeAreaInsets: EdgeInsets) -> some View {
        footerLayer(params: ContentView.FooterLayerParams(
            safeAreaInsets: safeAreaInsets,
            buttonHeight: buttonHeight,
            buttonWidth: buttonWidth,
            today: today,
            isRunning: timerVM.isRunning,
            isSessionFinished: timerVM.isSessionFinished,
            showingSideMenu: $showingSideMenu,
            onPause: { [weak timerVM] in
                Task { @MainActor in
                    await timerVM?.pauseTimer()
                }
            },
            onStart: { [weak timerVM] in
                isQuietMoonFocused = false
                Task { @MainActor in
                    await timerVM?.startTimer()
                }
            }
        ))
        .id("footer-\(timerVM.isRunning)-\(timerVM.isSessionFinished)")
    }

    @ViewBuilder
    func recordedTimesView(for context: LayoutContext, safeAreaInsets: EdgeInsets) -> some View {
        recordedTimesLayer(params: ContentView.RecordedTimesLayerParams(
            isLandscape: context.isLandscape,
            safeAreaInsets: safeAreaInsets,
            hasRecordedEndTime: timerVM.hasRecordedEndTime,
            isWorkSession: timerVM.isWorkSession,
            startTime: timerVM.startTime,
            endTime: timerVM.endTime,
            actualSessionMinutes: timerVM.actualSessionMinutes,
            showingEditRecord: $showingEditRecord
        ))
        .id("recorded-layer-\(recordedTimesNonce)")
    }
}

private extension ContentView {
    func applySceneHandlers<Content: View>(to view: Content, context: LayoutContext) -> some View {
        let withSession = attachSessionHandlers(view, context: context)
        let withLifecycle = attachLifecycleHandlers(withSession)
        let withHistory = attachHistoryHandlers(withLifecycle)
        return attachSideMenuHandler(withHistory, context: context)
    }
}

private extension ContentView {
    func attachSessionHandlers<Content: View>(_ view: Content, context: LayoutContext) -> some View {
        view
            .onReceive(timerVM.$flashStars.dropFirst()) { flashStars in
                if flashStars {
                    showDiamondStars = true
                }
            }
            .sheet(isPresented: $showingEditRecord) {
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
                } else {
                    // リセット時など、isSessionFinishedがfalseになったときにフォーカスを解除
                    isQuietMoonFocused = false
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: Notification.Name("TimerSilentCompleted")
                )
            ) { _ in
                silentCompleteWorkItem?.cancel()
                withAnimation(.easeInOut(duration: 0.2)) { showSilentCompleteChip = true }
                let work = DispatchWorkItem {
                    withAnimation(.easeInOut(duration: 0.3)) { showSilentCompleteChip = false }
                }
                silentCompleteWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4, execute: work)
            }
            .onChange(of: timerVM.endTime) { _, _ in
                recordedTimesNonce = UUID()
            }
    }

    func attachLifecycleHandlers<Content: View>(_ view: Content) -> some View {
        view
            .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
                isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
            }
            .onReceive(
                NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            ) { _ in
                today = Date()
                timerVM.appWillEnterForeground()
            }
            .onReceive(
                NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            ) { _ in
                timerVM.appDidEnterBackground()
            }
            .onAppear { scheduleMidnightTick() }
    }

    func attachHistoryHandlers<Content: View>(_ view: Content) -> some View {
        view
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("TimerEditSaved"))) { _ in
                savedToastWorkItem?.cancel()
                withAnimation(.easeInOut(duration: 0.2)) { showSavedToast = true }
                recordedTimesNonce = UUID()
                let work = DispatchWorkItem {
                    withAnimation(.easeInOut(duration: 0.3)) { showSavedToast = false }
                }
                savedToastWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6, execute: work)
            }
            .onReceive(
                NotificationCenter.default.publisher(for: Notification.Name("HistorySaveFailed"))
            ) { _ in
                historyToastWorkItem?.cancel()
                historyToastMessage = "Save failed. Retrying…"
                withAnimation(.easeInOut(duration: 0.2)) { showHistoryToast = true }
                let work = DispatchWorkItem {
                    withAnimation(.easeInOut(duration: 0.3)) { showHistoryToast = false }
                }
                historyToastWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6, execute: work)
            }
            .onReceive(
                NotificationCenter.default.publisher(for: Notification.Name("HistorySaveRetrying"))
            ) { notif in
                guard let delay = notif.object as? Double else { return }
                historyToastWorkItem?.cancel()
                historyToastMessage = String(format: "Retrying in %.0fs…", delay)
                withAnimation(.easeInOut(duration: 0.2)) { showHistoryToast = true }
                let work = DispatchWorkItem {
                    withAnimation(.easeInOut(duration: 0.3)) { showHistoryToast = false }
                }
                historyToastWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3, execute: work)
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("HistorySaveGaveUp"))) { _ in
                withAnimation(.easeInOut(duration: 0.2)) { showHistorySaveBanner = true }
            }
    }

    func attachSideMenuHandler<Content: View>(_ view: Content, context: LayoutContext) -> some View {
        view
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
                value: context.isLandscape
            )
    }
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
