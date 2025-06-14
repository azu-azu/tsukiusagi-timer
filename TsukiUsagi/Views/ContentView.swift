import SwiftUI

struct ContentView: View {

    // MARK: – State
    @StateObject private var historyVM: HistoryViewModel
    @StateObject private var timerVM:   TimerViewModel
    @State       private var showingSettings = false

    // MARK: – Const
    private let moonOffsetY: CGFloat = -150          // 月の高さオフセット
    private let timerBottomRatio: CGFloat = 0.90     // タイマーパネルの中心を「下端から 10 %」に
    private let startTimeGap: CGFloat   = 80         // 「開始 xx:xx」をタイトルとタイマーの“中間”へ

    // MARK: – Init
    init() {
        let history   = HistoryViewModel()
        _historyVM    = StateObject(wrappedValue: history)
        _timerVM      = StateObject(wrappedValue: TimerViewModel(historyVM: history))
    }

    // MARK: – Body
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    // 背景
                    BackgroundGradientView()
                    StarView()

                    // 月 or 終了メッセージ
                    ZStack {
                        if timerVM.isSessionFinished {

                            // タイトル
                            Text("おつかれさま 🌕")
                                .titleWhiteBold()
                                .offset(y: moonOffsetY)

                            // 開始時刻  →  タイマーの上 80pt に配置
                            VStack(spacing: 2) {
                                Text("start/  \(timerVM.formattedStartTime)")
                                Text("now/    \(Date(), style: .time)")
                            }
                            .titleWhiteBold()
                            .position(
                                x: geo.size.width  / 2,
                                y: geo.size.height * timerBottomRatio - startTimeGap
                            )
                        } else {
                            MoonView(offsetY: moonOffsetY,
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
                            y: geo.size.height * timerBottomRatio    // 下端から 10 %
                        )
                        .zIndex(2)
                }
                .ignoresSafeArea()    // Safe-Area を含めた高さ基準
            }

            // ツールバー ＆ シート
            .settingsToolbar(showing: $showingSettings)
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    DateDisplayView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    NavigationStack { ContentView() }
}
