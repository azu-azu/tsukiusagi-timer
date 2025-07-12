import SwiftUI

@main
struct TsukiUsagiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // ★ StateObject を「宣言だけ」
    @StateObject private var historyVM: HistoryViewModel
    @StateObject private var timerVM: TimerViewModel
    @StateObject private var sessionManagerV2 = SessionManagerV2()

    init() {
        // ★ 依存関係を組んでから StateObject に渡す
        let history = HistoryViewModel()
        _historyVM = StateObject(wrappedValue: history)
        _timerVM = StateObject(wrappedValue: TimerViewModel(historyVM: history))

        // Feature Flags の初期化
        FeatureFlags.setDefaultValues()

        NotificationManager.shared.requestAuthorization { ok in
            print(ok ? "Notification authorization granted."
                : "Notification authorization denied.")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // ★ "必ず" アプリ全体に配る
                .environmentObject(timerVM)
                .environmentObject(historyVM)
                .environmentObject(sessionManagerV2)
        }
    }
}
