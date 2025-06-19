import SwiftUI

struct ContentView: View {
    // State
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var timerVM:   TimerViewModel
    @State private var showingSettings = false
    @State private var showDiamondStars = false

    // Const
	private let moonTitle: String = "Centered"
	private let moonSize: CGFloat = 200
    private let moonPaddingY: CGFloat = 150          // 月の高さ調節
    private let finalPaddingY: CGFloat = 100          // 月の高さ調節
    private let timerBottomRatio: CGFloat = 0.85    // タイマーパネルの中心を「下端から X %」に
    private let startTimeGap: CGFloat   = 80        // 「開始 xx:xx」をタイトルとタイマーの"中間"へ

    private let finalTitle   = MoonMessage.finalTitle
    private let finalMessage = MoonMessage.random()

    // Body
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    BackgroundGradientView() // 背景
                    AwakeEnablerView(hidden: true) // 起動させておくためのダミー画面 ＊背景の次に置かないと色がつかない
                    StarView() // 固定スター
                    // 月 or 終了メッセージ
                    ZStack(alignment: .top) {
                        if timerVM.isSessionFinished {
                            // タイトル＆メッセージまとめて制御
                            VStack(spacing: 20) {
                                Text(finalTitle)
                                    .glitter(size: 24, resourceName: "gold")
                                    .frame(maxWidth: .infinity, alignment: .center)

                                Text(finalMessage)
                                    .titleWhite(size: 16, weight: .regular, design: .monospaced)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 32) // 左右
                            }
                            .padding(.top, finalPaddingY)

                        } else {
                            // moving star
                            FallingStarsView()
                            RisingStarsView()

                            // 🌕
                            MoonView(moonSize: moonSize,
                                    paddingY: moonPaddingY,
                                    glitterText: moonTitle)
                        }
                    }
                    .animation(.easeInOut(duration: 0.8),
                            value: timerVM.isSessionFinished)
                    .zIndex(1)

                    // フレーム最大化＋上端配置
                    .frame(maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .topLeading)

                    // タイマー ＆ Start ボタン
                    let timerHeight = CGFloat(geo.size.height * (1 - timerBottomRatio))
                    TimerPanel(timerVM: timerVM)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, timerHeight)


                    if showDiamondStars {
                        DiamondStarsOnceView()
                            .onAppear {
                                // アニメ寿命に合わせて自動非表示（例: 1秒後）
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                    showDiamondStars = false
                                }
                            }
                    }
                }
                // ★ TimerVM からのフラグ変化を拾う
                .onReceive(timerVM.$flashStars      // ← Publisher
                            .dropFirst()) { _ in  // ★ 最初の 1 発（起動時）を無視
                    showDiamondStars = true }


                // Safe-Area を含めた高さ基準
                .ignoresSafeArea()
            }

            // ツールバー ＆ シート
            .gearButtonToolbar(showing: $showingSettings)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .dateToolbar()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    // Preview は App ルートを通らんので自前注入
    let history = HistoryViewModel()
    let timer   = TimerViewModel(historyVM: history)
    return ContentView()
        .environmentObject(history)
        .environmentObject(timer)
}
