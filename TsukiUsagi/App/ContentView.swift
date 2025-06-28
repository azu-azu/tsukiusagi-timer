import SwiftUI

struct ContentView: View {

    // Environment
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var timerVM:   TimerViewModel

    // State
    @State private var showingSettings  = false
    @State private var showDiamondStars = false

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

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let size = geo.size
                let safeAreaInsets = geo.safeAreaInsets

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
                            let isLandscape = contentSize.width > contentSize.height

                            // 縦横別：比率で位置を決定
                            let setCenterY: CGFloat = isLandscape
                                ? centerY + contentSize.height * moonLandscapeYOffsetRatio
                                : centerY - contentSize.height * moonPortraitYOffsetRatio

                            // ※アニメーションを加える場合はwithAnimationで包むと良い
                            if timerVM.isSessionFinished {
                                // 終了時はQuietMoonViewのみ
                                VStack {
                                    QuietMoonView(size: size, safeAreaInsets: safeAreaInsets)
                                }
                                .frame(width: contentSize.width, height: setHeight)
                                .position(x: contentSize.width / 2, y: setCenterY)
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
                        // footerBarはZStackの一番下
                        footerBar()
                            .padding(.horizontal, 16)
                            .padding(.bottom, safeAreaInsets.bottom)
                            .zIndex(LayoutConstants.footerZIndex)

                        // --- RecordedTimesViewをfooterBarの直上に追加 ---
                        if timerVM.isSessionFinished && !timerVM.isWorkSession {
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
            .id(size)
            .allowsHitTesting(false)
            FlowingStarsView(
                starCount: 70,
                angle: .degrees(-90), // 上向き
                durationRange: 24...40,
                sizeRange: 2...4,
                spawnArea: nil
            )
            .id(size)
            .allowsHitTesting(false)
        }
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
