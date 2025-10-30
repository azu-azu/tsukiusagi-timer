#if DEBUG
import SwiftUI

/// プレビュー用のMockデータ
/// 本番コードへの逆流を防ぐため、単方向依存の構造を維持
@MainActor
struct PreviewData {
    // MARK: - View Models

    /// サンプルSessionManager
    static let sampleSessionManager: SessionManager = {
        let manager = SessionManager()
        // プレビュー用のカスタムセッションを追加
        try? manager.addOrUpdateEntry(
            originalKey: "",
            sessionName: "Preview Work",
            tasks: ["Sample session"]
        )
        try? manager.addOrUpdateEntry(
            originalKey: "",
            sessionName: "Preview Study",
            tasks: ["Another sample"]
        )
        return manager
    }()

    /// サンプルHistoryViewModel
    static let sampleHistoryVM: HistoryViewModel = {
        let historyViewModel = HistoryViewModel()
        // プレビュー用の履歴データを追加
        let parameters1 = AddSessionParameters(
            start: Date().addingTimeInterval(-3600),
            end: Date(),
            phase: .focus,
            sessionName: "Preview Work",
            task: "Sample session",
            memo: "This is a preview memo",
            completedSilently: false
        )
        historyViewModel.add(parameters: parameters1)

        let parameters2 = AddSessionParameters(
            start: Date().addingTimeInterval(-7200),
            end: Date().addingTimeInterval(-3600),
            phase: .focus,
            sessionName: "Preview Study",
            task: "Another sample",
            memo: nil,
            completedSilently: false
        )
        historyViewModel.add(parameters: parameters2)
        return historyViewModel
    }()

    /// サンプルTimerViewModel
    static let sampleTimerVM: TimerViewModel = {
        // ダミーサービスを用意
        class DummyEngine: TimerEngineable {
            var timeRemaining: Int = 0
            var isRunning: Bool = false
            var onTick: ((Int) -> Void)?
            var onSessionCompleted: ((TimerSessionInfo) -> Void)?
            func start(seconds: Int) {}
            func pause() {}
            func resume() {}
            func stop() {}
            func reset(to seconds: Int) {}
        }
        class DummyNotification: PhaseNotificationServiceable {
            func sendStartNotification() {}
            func cancelNotification() {}
            func cancelSessionEnd(for phase: PomodoroPhase) {}
            func cancelSessionEndSafely(for completedPhase: PomodoroPhase) {}
            func scheduleSessionEndNotification(after seconds: Int, phase: PomodoroPhase) {}
            func scheduleSessionEndNotification(at endAt: Date, phase: PomodoroPhase, timeSensitive: Bool) {}
            func rescheduleEnd(at endAt: Date, phase: PomodoroPhase, timeSensitive: Bool) {}
            func scheduleChainedSessionEnds(workEndAt: Date, breakEndAt: Date, timeSensitive: Bool) {}
            func ensureFocusAt(breakEndAt: Date, timeSensitive: Bool) {}
            func sendPhaseChangeNotification(for phase: PomodoroPhase) {}
            func cancelSessionEndNotification() {}
            func cancelSessionEndAll() {}
            func finalizeWorkPhase() {}
            func finalizeBreakPhase() {}
            func ensureAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) { completion(true) }
        }
        class DummyHaptic: HapticServiceable {
            func heavyImpact() {}
            func lightImpact() {}
        }
        class DummyHistory: SessionHistoryServiceable {
            func add(parameters: AddSessionParameters) {}
        }
        class DummyPersistence: TimerPersistenceManageable {
            var timeRemaining: Int = 0
            var isRunning: Bool = false
            var isWorkSession: Bool = true
            var runStateRaw: String?
            var endAtEpoch: Double?
            var remainingAtPause: Int?
            func saveTimerState() {}
            func restoreTimerState() {}
            func initializeWithWorkMinutes(_ minutes: Int) {}
        }
        class DummyFormatter: TimeFormatterUtilable {
            func format(seconds: Int) -> String { "00:00" }
            func format(date: Date?) -> String { "date" }
        }
        return TimerViewModel(
            engine: DummyEngine(),
            notificationService: DummyNotification(),
            hapticService: DummyHaptic(),
            historyService: DummyHistory(),
            persistenceManager: DummyPersistence(),
            formatter: DummyFormatter()
        )
    }()

    // MARK: - Preview Devices

    /// プレビュー用デバイス一覧
    static let previewDevices: [String] = [
        "iPhone 15 Pro",
        "iPhone 15 Pro Max",
        "iPhone 15",
        "iPhone 15 Plus",
        "iPhone SE (3rd generation)",
        "iPad Pro (12.9-inch) (6th generation)",
        "iPad Pro (11-inch) (4th generation)",
        "iPad Air (5th generation)",
        "iPad (10th generation)",
        "iPad mini (6th generation)"
    ]

    // MARK: - Sample Content

    /// サンプルテキスト
    enum SampleText {
        static let short = "Short text"
        static let medium = "This is a medium length text for testing purposes"
        static let long =
            "This is a very long text that should be used to test how the UI behaves when there is a lot of content. " +
            "It should wrap properly and maintain good readability."
        static let multiline = """
        This is a multiline text
        that spans multiple lines
        to test line wrapping
        and text layout.
        """
    }

    /// サンプル日付
    enum SampleDates {
        static let today = Date()
        static let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
        static let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: today) ?? today
        static let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: today) ?? today
    }

    // MARK: - Sample Session Items

    /// サンプルセッションアイテム
    static let sampleSessionItems: [SessionItem] = [
        SessionItem(
            id: UUID(),
            name: "Work",
            task: "Professional tasks",
            isFixed: true
        ),
        SessionItem(
            id: UUID(),
            name: "Study",
            task: "Learning activities",
            isFixed: true
        ),
        SessionItem(
            id: UUID(),
            name: "Read",
            task: "Reading time",
            isFixed: true
        ),
        SessionItem(
            id: UUID(),
            name: "Exercise",
            task: "Physical activity",
            isFixed: false
        ),
        SessionItem(
            id: UUID(),
            name: "Meditation",
            task: "Mindfulness practice",
            isFixed: false
        ),
        SessionItem(
            id: UUID(),
            name: "Creative Work",
            task: "Art and design",
            isFixed: false
        ),
        SessionItem(
            id: UUID(),
            name: "Planning",
            task: "Strategy and planning",
            isFixed: false
        ),
        SessionItem(
            id: UUID(),
            name: "Review",
            task: "Reflection time",
            isFixed: false
        )
    ]

    // MARK: - Sample Session Records

    /// サンプルセッションレコード
    static let sampleSessionRecords: [SessionRecord] = [
        SessionRecord(
            id: "20250106_090000",
            start: Date().addingTimeInterval(-3600),
            end: Date(),
            phase: .focus,
            sessionName: "Work",
            task: "Professional tasks",
            memo: "Completed the main project milestone",
            completedSilently: nil
        ),
        SessionRecord(
            id: "20250106_080000",
            start: Date().addingTimeInterval(-7200),
            end: Date().addingTimeInterval(-3600),
            phase: .focus,
            sessionName: "Study",
            task: "Learning activities",
            memo: "Reviewed SwiftUI documentation",
            completedSilently: nil
        ),
        SessionRecord(
            id: "20250106_070000",
            start: Date().addingTimeInterval(-10800),
            end: Date().addingTimeInterval(-7200),
            phase: .focus,
            sessionName: "Read",
            task: "Reading time",
            memo: "Finished chapter 5 of the book",
            completedSilently: nil
        )
    ]

    // MARK: - Environment Values

    /// プレビュー用の環境値（SwiftUIの EnvironmentValues と混同しない名称）
    struct PreviewEnv {
        /// 通常の環境値
        static let normal = PreviewEnv()

        /// アクセシビリティ対応の環境値
        static let accessibility = PreviewEnv(
            sizeCategory: .accessibilityExtraExtraExtraLarge,
            colorScheme: .dark,
            accessibilityReduceMotion: true
        )

        /// ダークモード
        static let darkMode = PreviewEnv(colorScheme: .dark)

        /// ライトモード
        static let lightMode = PreviewEnv(colorScheme: .light)

        // プロパティ
        let sizeCategory: ContentSizeCategory
        let colorScheme: ColorScheme
        let accessibilityReduceMotion: Bool

        init(
            sizeCategory: ContentSizeCategory = .medium,
            colorScheme: ColorScheme = .dark,
            accessibilityReduceMotion: Bool = false
        ) {
            self.sizeCategory = sizeCategory
            self.colorScheme = colorScheme
            self.accessibilityReduceMotion = accessibilityReduceMotion
        }
    }
}

// MARK: - Preview Helpers

extension View {
    /// プレビュー用の環境値を適用
    func previewEnvironment(_ values: PreviewData.PreviewEnv) -> some View {
        environment(\.sizeCategory, values.sizeCategory)
            .preferredColorScheme(values.colorScheme)
    }

    /// 複数のデバイスでプレビュー
    func previewDevices() -> some View {
        ForEach(PreviewData.previewDevices, id: \.self) { device in
            self
                .previewDevice(PreviewDevice(rawValue: device))
                .previewDisplayName(device)
        }
    }

    /// アクセシビリティ対応のプレビュー
    func previewAccessibility() -> some View {
        previewEnvironment(PreviewData.PreviewEnv.accessibility)
            .previewDisplayName("Accessibility")
    }

    /// ダーク/ライトモードのプレビュー
    func previewColorSchemes() -> some View {
        Group {
            self
                .previewEnvironment(PreviewData.PreviewEnv.lightMode)
                .previewDisplayName("Light Mode")

            self
                .previewEnvironment(PreviewData.PreviewEnv.darkMode)
                .previewDisplayName("Dark Mode")
        }
    }
}
#endif
