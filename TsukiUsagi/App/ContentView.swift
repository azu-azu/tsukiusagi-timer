import SwiftUI

struct ContentView: View {

    // Environment
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var timerVM:   TimerViewModel

    // State
    @State private var showingSettings  = false
    @State private var showDiamondStars = false

    // UI Const
    private let buttonWidth:  CGFloat = 120
    private let buttonHeight: CGFloat = 40
    private let moonTitle              = "Centered"
    private let moonSize:      CGFloat = 200
    private let moonPaddingY:  CGFloat = 100
    private let timerBottomRatio: CGFloat = 1.1   // 画面高に対する TimerPanel の比率

    // Body
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景レイヤ
                BackgroundGradientView()
                    .ignoresSafeArea()

                AwakeEnablerView(hidden: true)
                StarView().allowsHitTesting(false)

                // 月 & 星レイヤ
                ZStack(alignment: .top) {
                    if timerVM.isSessionFinished {
                        // 🌑
                        QuietMoonView()
                    } else {
                        // ⭐️
                        FallingStarsView().allowsHitTesting(false)
                        RisingStarsView().allowsHitTesting(false)

                        // 🌕
                        MoonView(
                            moonSize: moonSize,
                            paddingY: moonPaddingY,
                            glitterText: moonTitle
                        )
                            .allowsHitTesting(false)
                    }
                }
                .animation(.easeInOut(duration: 0.8),
                            value: timerVM.isSessionFinished)

                // タイマー
                GeometryReader { geo in
                    let timerHeight = geo.size.height * (1 - timerBottomRatio)
                    TimerPanel(timerVM: timerVM)
                        .frame(maxWidth: .infinity,
                                maxHeight: .infinity,
                                alignment: .bottom)
                        .padding(.bottom, timerHeight)
                }
            }

            // 💠 ダイヤモンドスター
            .overlay(alignment: .center) {
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

            // フッターを最背面に貼り付け
            .overlay(alignment: .bottom) {
                footerBar()
                    .padding(.horizontal, 16)  // 左右余白
                    .padding(.bottom, 10)      // 下端から Ypt 浮かす（数字で微調整）
            }
            .onReceive(timerVM.$flashStars.dropFirst()) { _ in
                showDiamondStars = true
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // Footer
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
        .frame(height: buttonHeight) // ← 全体フッターの高さ定義
        .background(Color.black.opacity(0.0001)) // タッチ領域確保
    }

    // START / PAUSE
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
