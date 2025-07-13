import SwiftUI

@main
struct TsukiUsagiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // StateObjects: declaration only
    @StateObject private var historyVM: HistoryViewModel
    @StateObject private var timerVM: TimerViewModel
    @StateObject private var sessionManager: SessionManager
    @StateObject private var sessionManagerV2: SessionManagerV2

    // Service singletons
    private let timerEngine: TimerEngineable
    private let hapticService: HapticService
    private let notificationService: PhaseNotificationServiceable
    private let formatter: TimeFormatterUtil
    private let historyService: SessionHistoryServiceable
    private let persistenceManager: TimerPersistenceManager

    init() {
        // Construct services first
        let timerEngine: TimerEngineable

        #if targetEnvironment(simulator)
        print("✅ Using MockTimerEngine")
        timerEngine = MockTimerEngine()
        #else
        print("✅ Using TimerEngine")
        timerEngine = TimerEngine()
        #endif

        let hapticService = HapticService()
        let formatter = TimeFormatterUtil()
        let notificationService = PhaseNotificationService(hapticService: hapticService)
        let historyService = SessionHistoryService(formatter: formatter)
        let persistenceManager = TimerPersistenceManager()

        // Assign to lets
        self.timerEngine = timerEngine
        self.hapticService = hapticService
        self.notificationService = notificationService
        self.formatter = formatter
        self.historyService = historyService
        self.persistenceManager = persistenceManager

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
        _sessionManagerV2 = StateObject(wrappedValue: SessionManagerV2())

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
                .environmentObject(timerVM)
                .environmentObject(historyVM)
                .environmentObject(sessionManager)
                .environmentObject(sessionManagerV2)
        }
    }
}
