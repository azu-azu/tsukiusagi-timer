import SwiftUI
import CoreText

@main
struct TsukiUsagiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // StateObjects: declaration only
    @StateObject private var historyVM: HistoryViewModel
    @StateObject private var timerVM: TimerViewModel
    @StateObject private var sessionManager: SessionManager

    // Service singletons
    private let timerEngine: TimerEngineable
    private let hapticService: HapticService
    private let notificationService: PhaseNotificationServiceable
    private let formatter: TimeFormatterUtil
    private let historyService: SessionHistoryServiceable
    private let persistenceManager: TimerPersistenceManager

    init() {
        // ハプティックフィードバックの事前初期化
        _ = HapticManager.shared

        // Construct services first
        let timerEngine: TimerEngineable = TimerEngine()
        print("✅ Using TimerEngine for all environments")

        let hapticService = HapticService()
        let formatter = TimeFormatterUtil()
        let notificationService = PhaseNotificationService(hapticService: hapticService)
        let historyService = SessionHistoryService(formatter: formatter)
        let persistenceManager = TimerPersistenceManager()

        // Assign to lets
        self.timerEngine = timerEngine
        self.hapticService = hapticService
        self.notificationService = notificationService
        self.historyService = historyService
        self.persistenceManager = persistenceManager
        self.formatter = formatter

        // StateObjects
        _historyVM = StateObject(wrappedValue: HistoryViewModel())
        _timerVM = StateObject(wrappedValue: TimerViewModel(
            engine: timerEngine,
            notificationService: notificationService,
            hapticService: hapticService,
            historyService: historyService,
            persistenceManager: persistenceManager,
            formatter: formatter
        ))
        _sessionManager = StateObject(wrappedValue: SessionManager())

        // Feature Flags の初期化
        FeatureFlags.setDefaultValues()
        NotificationManager.shared.requestAuthorization { ok in
            print(ok ? "Notification authorization granted."
                : "Notification authorization denied.")
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
        print("🔤 カスタムフォント登録開始...")

        let fontFiles = ["Nunito-Bold.ttf", "Nunito-Italic.ttf", "Nunito-Medium.ttf", "Nunito-Regular.ttf"]

        for fontFile in fontFiles {
            guard let fontURL = Bundle.main.url(
                forResource: fontFile.replacingOccurrences(of: ".ttf", with: ""),
                withExtension: "ttf"
            ) else {
                print("❌ フォントファイルが見つかりません: \(fontFile)")
                continue
            }

            var error: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)

            if success {
                print("✅ フォント登録成功: \(fontFile)")
            } else {
                let errorDescription = error?.takeRetainedValue().localizedDescription ?? "不明なエラー"
                print("❌ フォント登録失敗: \(fontFile) - \(errorDescription)")
            }
        }

        print("🔤 カスタムフォント登録完了")
    }
    
    private func configureNavigationBarAppearance() {
        print("🎨 NavigationBar外観設定開始...")
        
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
        
        print("✅ NavigationBar外観設定完了")
    }
}
