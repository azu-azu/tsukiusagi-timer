import SwiftUI
import CoreText
import ActivityKit

@main
struct TsukiUsagiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // DI Container
    private let container: DependencyContainer

    // StateObjects (Container提供のインスタンスを注入)
    @StateObject private var historyVM: HistoryViewModel
    @StateObject private var timerVM: TimerViewModel
    @StateObject private var sessionManager: SessionManager

    init() {
        // ハプティックフィードバックの事前初期化
        _ = HapticManager.shared

        // DIコンテナ生成（ローカル変数で参照を固定）
        let c = DependencyContainer()
        self.container = c

        // StateObjects — Container から注入
        _historyVM = StateObject(wrappedValue: c.historyVM)
        _timerVM = StateObject(wrappedValue: c.timerVM)
        _sessionManager = StateObject(wrappedValue: c.sessionManager)

        // Feature Flags の初期化
        FeatureFlags.setDefaultValues()

        // NavigationBar外観設定
        configureNavigationBarAppearance()

        // カスタムフォントの登録
        registerCustomFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timerVM)
                .environmentObject(historyVM)
                .environmentObject(sessionManager)
                .onOpenURL { url in
                    DeepLinkRouter.shared.handle(url: url)
                }
                .task {
                    // アプリ起動時に孤児Activityをクリーンアップ
                    await cleanupOrphanActivities()
                }
        }
    }

    private func registerCustomFonts() {

        let fontFiles = ["Nunito-Bold.ttf", "Nunito-Italic.ttf", "Nunito-Medium.ttf", "Nunito-Regular.ttf"]

        for fontFile in fontFiles {
            guard let fontURL = Bundle.main.url(
                forResource: fontFile.replacingOccurrences(of: ".ttf", with: ""),
                withExtension: "ttf"
            ) else {
                continue
            }

            var error: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)

            if success {
                // フォント登録成功
			} else if (error?.takeRetainedValue() as Error?) != nil {
                // 既に登録済みなどの場合はスキップ扱い（必要に応じてエラーコード分岐可）
            } else {
                // その他のエラー
            }
        }

    }

    private func configureNavigationBarAppearance() {

        // NavigationBarの外観設定
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()

        // 背景色とタイトル色をDesignTokensに従って設定
        appearance.backgroundColor = UIColor(DesignTokens.CosmosColors.background)
        appearance.titleTextAttributes = [
            .foregroundColor: DesignTokens.UIColors.textWhite,
            .font: DesignTokens.UIKitFonts.navigationTitle
        ]

        // すべてのNavigationBarに適用
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance

    }

    /// アプリ起動時に残存する孤児Live Activityを終了
    private func cleanupOrphanActivities() async {
        #if DEBUG
        let activeCountBefore = Activity<TimerActivityAttributes>.activities.count
        print("🌙 Cleanup: Active activities count = \(activeCountBefore)")
        #endif

        for activity in Activity<TimerActivityAttributes>.activities {
            let dismissPolicy: ActivityUIDismissalPolicy = .immediate
            let currentContentState = TimerActivityAttributes.ContentState(
                endsAt: Date(),
                isPaused: false
            )
            await activity.end(.init(state: currentContentState, staleDate: nil), dismissalPolicy: dismissPolicy)

            #if DEBUG
            print("🌙 Cleanup: Ended orphan activity (\(activity.id))")
            #endif
        }

        #if DEBUG
        let activeCountAfter = Activity<TimerActivityAttributes>.activities.count
        print("🌙 Cleanup: Active activities count after = \(activeCountAfter)")
        #endif
    }
}
