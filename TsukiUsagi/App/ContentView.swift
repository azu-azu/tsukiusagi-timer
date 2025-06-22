import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var timerVM:   TimerViewModel
    @State private var showingSettings = false
    @State private var showDiamondStars = false

    private let buttonWidth: CGFloat = 120
    private let expandDuration: Double = 0.3
    private let moonTitle = "Centered"
    private let moonSize: CGFloat = 200
    private let moonPaddingY: CGFloat = 150
    private let timerBottomRatio: CGFloat = 0.85   // ← TimerPanel の高さバランス

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景だけ Safe-Area を無視
                BackgroundGradientView()
                    .ignoresSafeArea()

                AwakeEnablerView(hidden: true)
                StarView().allowsHitTesting(false)

                // 月 & 星エフェクト
                ZStack(alignment: .top) {
                    if timerVM.isSessionFinished {
                        QuietMoonView()
                    } else {
                        // ⭐️
                        FallingStarsView()
                            .allowsHitTesting(false)
                        RisingStarsView()
                            .allowsHitTesting(false)

                        // 🌕
                        MoonView(
                            moonSize: moonSize,
                            paddingY: moonPaddingY,
                            glitterText: moonTitle
                        )
                        .allowsHitTesting(false)
                    }
                }
                .animation(.easeInOut(duration: 0.8), value: timerVM.isSessionFinished)

                // 中央タイマー
                GeometryReader { geo in
                    let timerHeight = geo.size.height * (1 - timerBottomRatio)
                    TimerPanel(timerVM: timerVM)
                        .frame(maxWidth: .infinity,
                                maxHeight: .infinity,
                                alignment: .bottom)
                        .padding(.bottom, timerHeight)
                }
            }
            // ▼▼▼ 最下部フッター ▼▼▼
            .safeAreaInset(edge: .bottom) {
                footerBar()
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    // 少し透過でも OK
                    .background(.black.opacity(0.0001)) // ← タッチ領域確保
            }
            // ▼ ダイヤモンドスター一瞬
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
            // ▼ イベント
            .onReceive(timerVM.$flashStars.dropFirst()) { _ in
                showDiamondStars = true
            }
            // ▼ シート & ツールバー
            .sheet(isPresented: $showingSettings) { SettingsView() }
            // .dateToolbar()
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // --- フッター View ---
    @ViewBuilder
    private func footerBar() -> some View {
        HStack {
            // 日付
            Text(AppFormatters.displayDate.string(from: Date()))
                .titleWhite(size: 16,
                            weight: .regular,
                            design: .monospaced)

            Spacer(minLength: 24)

            // start pause ボタン
            startPauseButton()

            Spacer(minLength: 24)

            // gearボタン
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.white)
            }
        }
    }

    // --- START/PAUSE ボタン ---
    private func startPauseButton() -> some View {
        Button(timerVM.isRunning ? "PAUSE" : "START") {
            timerVM.isRunning ? timerVM.stopTimer() : timerVM.startTimer()
        }
        .padding(.vertical, 12)
        .frame(width: buttonWidth)
        .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 20))
        .titleWhiteAvenir(weight: .bold)
        .foregroundColor(.white)
        .scaleEffect(1.0)
    }
}

#Preview {
    let history = HistoryViewModel()
    let timer   = TimerViewModel(historyVM: history)
    ContentView()
        .environmentObject(history)
        .environmentObject(timer)
}
