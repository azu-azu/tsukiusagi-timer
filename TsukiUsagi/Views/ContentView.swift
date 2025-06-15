import SwiftUI

struct ContentView: View {

    // State
    @StateObject private var historyVM: HistoryViewModel
    @StateObject private var timerVM:   TimerViewModel
    @State       private var showingSettings = false

    // Const
	private let moonSize: CGFloat = 200
    private let moonOffsetY: CGFloat = -150          // 月の高さオフセット
    private let timerBottomRatio: CGFloat = 0.85     // タイマーパネルの中心を「下端から X %」に
    private let startTimeGap: CGFloat   = 80         // 「開始 xx:xx」をタイトルとタイマーの“中間”へ

    // Init
    init() {
        let history   = HistoryViewModel()
        _historyVM    = StateObject(wrappedValue: history)
        _timerVM      = StateObject(wrappedValue: TimerViewModel(historyVM: history))
    }

    // Body
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    // 背景
                    BackgroundGradientView()
                    AwakeEnablerView(hidden: true)
                    StarView()

                    // 月 or 終了メッセージ
                    ZStack {
                        if timerVM.isSessionFinished {
                            // タイトル
                            Text("おつかれさま 🌕")
                                .titleWhite()
                                .offset(y: moonOffsetY)

                            // 開始時刻  →  タイマーの上 80pt に配置
                            VStack(spacing: 2) {
                                Text("start  ⏳  \(timerVM.formattedStartTime)")
                                Text("final  ⌛️  \(Date(), style: .time)")
                            }
                            .titleWhiteAvenir()
                            .position(
                                x: geo.size.width  / 2,
                                y: geo.size.height * timerBottomRatio - startTimeGap
                            )
                        } else {
                            MoonView(moonSize: moonSize,
                                    offsetY: moonOffsetY,
                                    glitterText: "studying")
                        }
                    }
                    .animation(.easeInOut(duration: 0.8),
                            value: timerVM.isSessionFinished)
                    .zIndex(1)

                    // タイマー ＆ Start ボタン
                    TimerPanel(timerVM: timerVM)
                        .position(
                            x: geo.size.width / 2,
                            y: geo.size.height * timerBottomRatio
                        )
                        .zIndex(2)
                }
                .ignoresSafeArea()    // Safe-Area を含めた高さ基準
            }

            // ツールバー ＆ シート
            .gearButtonToolbar(showing: $showingSettings)
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .dateToolbar()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    NavigationStack { ContentView() }
}
