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
    private let buttonHeight: CGFloat = 40
    private let moonSize: CGFloat = 200
    private let timerHeight: CGFloat = 60 // TimerPanelの高さ（仮）
    private let timerSpacing: CGFloat = 80 // 月とtimerの間
    private let timerBottomRatio: CGFloat = 1.1   // 画面高に対する TimerPanel の比率

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let size = geo.size
                let safeAreaInsets = geo.safeAreaInsets
                let overshoot: CGFloat = 200

                if size.width > 0 && size.height > 0 {
                    ZStack(alignment: .bottom) {
                        // 背景レイヤ
                        BackgroundGradientView().ignoresSafeArea()
                        AwakeEnablerView(hidden: true)
                        StaticStarsView(size: size, safeAreaInsets: safeAreaInsets).allowsHitTesting(false)
                        // FlowingStarsViewなどの星エフェクトはタイマー進行中のみ
                        if !timerVM.isSessionFinished {
                            FlowingStarsView(
                                mode: .vertical(direction: .down),
                                size: size,
                                safeAreaInsets: safeAreaInsets,
                                overshoot: overshoot
                            ).allowsHitTesting(false)
                            FlowingStarsView(
                                mode: .vertical(direction: .up),
                                size: size,
                                safeAreaInsets: safeAreaInsets,
                                overshoot: overshoot
                            ).allowsHitTesting(false)
                        }
                        // Moon+Timerセット or QuietMoonView
                        GeometryReader { geo2 in
                            let contentSize = geo2.size
                            let moonHeight: CGFloat = moonSize
                            let timerHeight: CGFloat = 60 // TimerPanelの高さ（仮）
                            let spacing: CGFloat = 80
                            let setHeight = moonHeight + spacing + timerHeight
                            let centerY = contentSize.height / 2
                            let setCenterY = centerY - 100

                            if timerVM.isSessionFinished {
                                // 終了時はQuietMoonViewのみ
                                VStack {
                                    QuietMoonView(size: size, safeAreaInsets: safeAreaInsets)
                                }
                                .frame(width: contentSize.width, height: setHeight)
                                .position(x: contentSize.width / 2, y: setCenterY)
                            } else {
                                // 進行中はMoon+Timerセット
                                VStack(spacing: spacing) {
                                    MoonView(
                                        moonSize: moonSize,
                                        glitterText: moonTitle,
                                        size: size
                                    )
                                    .allowsHitTesting(false)
                                    TimerPanel(timerVM: timerVM)
                                        .frame(height: timerHeight)
                                }
                                .frame(width: contentSize.width, height: setHeight)
                                .position(x: contentSize.width / 2, y: setCenterY)
                            }
                        }
                        // footerBarはZStackの一番下
                        footerBar()
                            .padding(.horizontal, 16)
                            .padding(.bottom, safeAreaInsets.bottom)
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
        .animation(.easeInOut(duration: 0.8),
                    value: timerVM.isSessionFinished)
    }

    // MARK: - Background Stars Layer

    @ViewBuilder
    private func backgroundStarsLayer(size: CGSize, safeAreaInsets: EdgeInsets, overshoot: CGFloat) -> some View {
        ZStack {
            BackgroundGradientView().ignoresSafeArea()
            AwakeEnablerView(hidden: true)
            StaticStarsView(size: size, safeAreaInsets: safeAreaInsets)
                .allowsHitTesting(false)
            FlowingStarsView(
                mode: .vertical(direction: .down),
                size: size,
                safeAreaInsets: safeAreaInsets,
                overshoot: overshoot
            )
            .allowsHitTesting(false)
            FlowingStarsView(
                mode: .vertical(direction: .up),
                size: size,
                safeAreaInsets: safeAreaInsets,
                overshoot: overshoot
            )
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
    }

    // MARK: - Start / Pause Button

    private func startPauseButton() -> some View {
        Button(timerVM.isRunning ? "PAUSE" : "START") {
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
