import SwiftUI

// MARK: - PreferenceKey for Landscape Detection
struct LandscapePreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

struct ContentView: View {

    // Environment
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var timerVM:   TimerViewModel

    // Environment for Orientation and Accessibility
    @Environment(\.horizontalSizeClass) private var horizontalClass
    @Environment(\.verticalSizeClass) private var verticalClass
    @Environment(\.sizeCategory) private var sizeCategory

    // State
    @State private var showingSettings  = false
    @State private var showDiamondStars = false
    @State private var cachedIsLandscape: Bool = false
    @FocusState private var isQuietMoonFocused: Bool

    private let moonTitle = "Centered"

    // UI Const
    private let buttonWidth: CGFloat = 120
    private let buttonHeight: CGFloat = LayoutConstants.footerBarHeight
    private let moonSize: CGFloat = 200
    private let timerHeight: CGFloat = 60 // TimerPanelの高さ（仮）
    private let timerSpacing: CGFloat = 80 // 月とtimerの間

    // 比率定数
    private let timerBottomRatio: CGFloat = 1.1   // 画面高に対する TimerPanel の比率
    private let moonPortraitYOffsetRatio: CGFloat = 0.15 // landscape時のmoonは少し下げる
    private let moonLandscapeYOffsetRatio: CGFloat = 0.1 // portrait時のmoonは少し上げる

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
                        StaticStarsView(starCount: 40)
                        // FlowingStarsViewなどの星エフェクトはタイマー進行中のみ
                        if !timerVM.isSessionFinished {
                            FlowingStarsView(
                                starCount: 70,
                                angle: .degrees(90), // 下向き
                                durationRange: 24...40,
                                sizeRange: 2...4,
                                spawnArea: nil
                            )
                            FlowingStarsView(
                                starCount: 70,
                                angle: .degrees(-90), // 上向き
                                durationRange: 24...40,
                                sizeRange: 2...4,
                                spawnArea: nil
                            )
                        }

                        // Moon+Timerセット or QuietMoonView
                        GeometryReader { geo2 in
                            let contentSize = geo2.size
                            let safeTop = geo2.safeAreaInsets.top
                            let safeBottom = geo2.safeAreaInsets.bottom
                            let setHeight = moonSize + timerSpacing + timerHeight

                            // SafeAreaを考慮した中央
                            let centerY = (contentSize.height - safeTop - safeBottom) / 2 + safeTop

                            // 縦横別：比率で位置を決定
                            let setCenterY: CGFloat = isLandscape
                                ? centerY + contentSize.height * moonLandscapeYOffsetRatio
                                : centerY - contentSize.height * moonPortraitYOffsetRatio

                            if timerVM.isSessionFinished {
                                // 終了時はQuietMoonViewのみ
                                if isLandscape {
                                    // 横画面：左右分割（最高品質版）
                                    HStack(spacing: landscapeMargin) {
                                        // 左側：QuietMoonView
                                        QuietMoonView(size: size, safeAreaInsets: safeAreaInsets)
                                            .frame(width: (contentSize.width - landscapeMargin) * 0.5, height: setHeight)
                                            .background(Color.clear)
                                            .zIndex(10)
                                            .layoutPriority(1) // 左側を優先的に表示
                                            .accessibilityLabel("Quiet Moon Message")
                                            .accessibilityHint("Displays inspirational messages after session completion")
                                            .accessibilityAddTraits(.isHeader)
                                            .focused($isQuietMoonFocused)

                                        // 右側：RecordedTimesView
                                        VStack {
                                            Spacer()
                                            RecordedTimesView(
                                                formattedStartTime: timerVM.formattedStartTime,
                                                formattedEndTime: timerVM.formattedEndTime,
                                                actualSessionMinutes: timerVM.actualSessionMinutes,
                                                onEdit: { showingSettings = true }
                                            )
                                            .sessionVisibility(isVisible: timerVM.isSessionFinished)
                                            .sessionEndTransition(timerVM)
                                            Spacer()
                                        }
                                        .frame(width: (contentSize.width - landscapeMargin) * 0.5, height: setHeight)
                                        .background(Color.clear)
                                        .zIndex(10)
                                        .layoutPriority(0) // 右側は必要に応じて縮小
                                        .accessibilityLabel("Session Record")
                                        .accessibilityHint("Shows start time, end time, and session duration")
                                    }
                                    .frame(width: contentSize.width, height: setHeight)
                                    .position(x: contentSize.width / 2, y: setCenterY)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .leading).combined(with: .opacity),
                                        removal: .move(edge: .trailing).combined(with: .opacity)
                                    ))
                                    .preference(key: LandscapePreferenceKey.self, value: isLandscape)
                                } else {
                                    // 縦画面：従来通り
                                    VStack {
                                        QuietMoonView(size: size, safeAreaInsets: safeAreaInsets)
                                            .accessibilityLabel("Quiet Moon Message")
                                            .accessibilityHint("Displays inspirational messages after session completion")
                                            .accessibilityAddTraits(.isHeader)
                                            .focused($isQuietMoonFocused)
                                    }
                                    .frame(width: contentSize.width, height: setHeight)
                                    .position(x: contentSize.width / 2, y: setCenterY)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .top).combined(with: .opacity),
                                        removal: .move(edge: .bottom).combined(with: .opacity)
                                    ))
                                    .preference(key: LandscapePreferenceKey.self, value: isLandscape)
                                }
                            } else {
                                // 進行中はMoon+Timerセット
                                VStack(spacing: 80) {
                                    MoonView(
                                        moonSize: moonSize,
                                        glitterText: moonTitle,
                                        size: size
                                    )
                                    .allowsHitTesting(false)
                                    TimerPanel(timerVM: timerVM)
                                        .frame(height: 60)
                                }
                                .frame(width: contentSize.width, height: setHeight)
                                .position(x: contentSize.width / 2, y: setCenterY)
                            }
                        }
                        .onPreferenceChange(LandscapePreferenceKey.self) { newValue in
                            // 親Viewで向き変更を検知
                            updateOrientation(size: size)
                        }

                        // footerBarはZStackの一番下
                        footerBar()
                            .padding(.horizontal, 16)
                            .padding(.bottom, safeAreaInsets.bottom)
                            .zIndex(LayoutConstants.footerZIndex)

                        // --- RecordedTimesViewを縦画面時のみfooterBarの直上に追加 ---
                        if timerVM.isSessionFinished && !timerVM.isWorkSession && !isLandscape {
                            RecordedTimesView(
                                formattedStartTime: timerVM.formattedStartTime,
                                formattedEndTime: timerVM.formattedEndTime,
                                actualSessionMinutes: timerVM.actualSessionMinutes,
                                onEdit: { showingSettings = true }
                            )
                            .sessionVisibility(isVisible: timerVM.isSessionFinished)
                            .padding(.bottom, LayoutConstants.footerBarHeight + safeAreaInsets.bottom + LayoutConstants.recordedTimesBottomSpacing)
                            .zIndex(LayoutConstants.overlayZIndex)
                            .sessionEndTransition(timerVM)
                        }

                        // 💠 ダイヤモンドスター
                        if showDiamondStars {
                            DiamondStarsOnceView()
                                .allowsHitTesting(false)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                        showDiamondStars = false
                                    }
                                }
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
                    }
                    .onChange(of: timerVM.isSessionFinished) { oldValue, newValue in
                        if newValue {
                            // セッション終了時にQuietMoonViewにフォーカスを飛ばす
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isQuietMoonFocused = true
                            }
                        }
                    }
                    .animation(
                        .easeInOut(duration: 0.3)
                        .delay(0.1), // 少し遅延させて自然に
                        value: isLandscape
                    )
                }
            }
        }
    }

    // MARK: - Moon Layer

    @ViewBuilder
    private func moonLayer(size: CGSize, safeAreaInsets: EdgeInsets) -> some View {
        ZStack(alignment: .top) {
            if timerVM.isSessionFinished {
                QuietMoonView(size: size, safeAreaInsets: safeAreaInsets)
            } else {
                MoonView(
                    moonSize: moonSize,
                    glitterText: moonTitle,
                    size: size
                )
                .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: LayoutConstants.sessionEndAnimationDuration),
                    value: timerVM.isSessionFinished)
    }

    // MARK: - Background Stars Layer

    @ViewBuilder
    private func backgroundStarsLayer(size: CGSize, safeAreaInsets: EdgeInsets, overshoot: CGFloat) -> some View {
        ZStack {
            BackgroundGradientView().ignoresSafeArea()
            AwakeEnablerView(hidden: true)
            StaticStarsView(starCount: 40)
            FlowingStarsView(
                starCount: 70,
                angle: .degrees(90), // 下向き
                durationRange: 24...40,
                sizeRange: 2...4,
                spawnArea: nil
            )
            .id(roundedSize(size)) // 微差を防ぐため整数に丸める
            .allowsHitTesting(false)
            FlowingStarsView(
                starCount: 70,
                angle: .degrees(-90), // 上向き
                durationRange: 24...40,
                sizeRange: 2...4,
                spawnArea: nil
            )
            .id(roundedSize(size)) // 微差を防ぐため整数に丸める
            .allowsHitTesting(false)
        }
    }

    // MARK: - Helper Methods

    /// CGSize の微差を防ぐため整数に丸める
    private func roundedSize(_ size: CGSize) -> CGSize {
        return CGSize(
            width: round(size.width),
            height: round(size.height)
        )
    }

    // MARK: - Footer

    @ViewBuilder
    private func footerBar() -> some View {
        ZStack(alignment: .bottom) {
            HStack {
                Text(DateFormatters.displayDateNoYear.string(from: Date()))
                    .titleWhite(size: 16,
                                weight: .bold,
                                design: .monospaced)
                    .frame(height: buttonHeight, alignment: .bottom)

                Spacer(minLength: 0)

                Button { showingSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .frame(width: buttonHeight,
                                height: buttonHeight,
                                alignment: .bottom)
                        .foregroundColor(.white)
                }
            }

            startPauseButton()
                .frame(height: buttonHeight, alignment: .bottom)
                .offset(y: 6)
        }
        .frame(height: buttonHeight)
        .background(Color.black.opacity(0.0001))
        .zIndex(LayoutConstants.overlayZIndex)
    }

    // MARK: - Start / Pause Button

    private func startPauseButton() -> some View {
        Button(timerVM.isRunning ? "PAUSE" : "START") {
            HapticManager.shared.buttonTapFeedback() // ハプティックフィードバック
            timerVM.isRunning ? timerVM.stopTimer()
                                : timerVM.startTimer()
        }
        .frame(width: buttonWidth, height: buttonHeight)
        .background(Color.white.opacity(0.2),
                    in: RoundedRectangle(cornerRadius: 20))
        .titleWhiteAvenir(weight: .bold)
        .foregroundColor(.white)
    }
}

#Preview {
    let history = HistoryViewModel()
    let timer   = TimerViewModel(historyVM: history)
    ContentView()
        .environmentObject(history)
        .environmentObject(timer)
}
