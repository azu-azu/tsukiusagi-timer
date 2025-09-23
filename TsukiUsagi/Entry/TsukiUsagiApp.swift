import SwiftUI
import CoreText

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

        // 通知許可のリクエスト（初回起動時のみ）
        Task {
            let granted = await NotificationPermissionManager.shared.requestPermissionIfNeeded()
            if granted {
                #if DEBUG
                print("🔔 通知許可が承認されました - バックグラウンド時の終了通知が有効です")
                #endif
            } else {
                #if DEBUG
                print("🔔 通知許可が拒否されました - バックグラウンド時の終了通知は無効です")
                #endif
            }
        }

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
        }
    }

    private func registerCustomFonts() {
        #if DEBUG
        print("🔤 カスタムフォント登録開始...")
        #endif

        let fontFiles = ["Nunito-Bold.ttf", "Nunito-Italic.ttf", "Nunito-Medium.ttf", "Nunito-Regular.ttf"]

        for fontFile in fontFiles {
            guard let fontURL = Bundle.main.url(
                forResource: fontFile.replacingOccurrences(of: ".ttf", with: ""),
                withExtension: "ttf"
            ) else {
                #if DEBUG
                print("❌ フォントファイルが見つかりません: \(fontFile)")
                #endif
                continue
            }

            var error: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)

            if success {
                #if DEBUG
                print("✅ フォント登録成功: \(fontFile)")
                #endif
            } else if let e = error?.takeRetainedValue() as Error? {
                // 既に登録済みなどの場合はスキップ扱い（必要に応じてエラーコード分岐可）
                #if DEBUG
                print("ℹ️ skip or failed: \(fontFile) — \(e.localizedDescription)")
                #endif
            } else {
                #if DEBUG
                print("ℹ️ skip or failed: \(fontFile)")
                #endif
            }
        }

        #if DEBUG
        print("🔤 カスタムフォント登録完了")
        #endif
    }

    private func configureNavigationBarAppearance() {
        #if DEBUG
        print("🎨 NavigationBar外観設定開始...")
        #endif

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

        #if DEBUG
        print("✅ NavigationBar外観設定完了")
        #endif
    }
}
