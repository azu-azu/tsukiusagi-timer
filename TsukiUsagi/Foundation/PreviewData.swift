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
        try? manager.addSession(
            SessionItem(
                id: UUID(),
                name: "Preview Work",
                subtitle: "Sample session",
                isFixed: false
            )
        )
        try? manager.addSession(
            SessionItem(
                id: UUID(),
                name: "Preview Study",
                subtitle: "Another sample",
                isFixed: false
            )
        )
        return manager
    }()

    /// サンプルHistoryViewModel
    static let sampleHistoryVM: HistoryViewModel = {
        let historyViewModel = HistoryViewModel()
        // プレビュー用の履歴データを追加
        historyViewModel.add(
            start: Date().addingTimeInterval(-3600),
            end: Date(),
            phase: .focus,
            activity: "Preview Work",
            subtitle: "Sample session",
            memo: "This is a preview memo"
        )
        historyViewModel.add(
            start: Date().addingTimeInterval(-7200),
            end: Date().addingTimeInterval(-3600),
            phase: .focus,
            activity: "Preview Study",
            subtitle: "Another sample",
            memo: nil
        )
        return historyViewModel
    }()

    /// サンプルTimerViewModel
    static let sampleTimerVM: TimerViewModel = {
        let timer = TimerViewModel(historyVM: sampleHistoryVM, activityLabel: "Preview Work", subtitleLabel: "Sample session")
        return timer
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
        static let long = "This is a very long text that should be used to test how the UI behaves when there is a lot of content. It should wrap properly and maintain good readability."
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
            subtitle: "Professional tasks",
            isFixed: true
        ),
        SessionItem(
            id: UUID(),
            name: "Study",
            subtitle: "Learning activities",
            isFixed: true
        ),
        SessionItem(
            id: UUID(),
            name: "Read",
            subtitle: "Reading time",
            isFixed: true
        ),
        SessionItem(
            id: UUID(),
            name: "Exercise",
            subtitle: "Physical activity",
            isFixed: false
        ),
        SessionItem(
            id: UUID(),
            name: "Meditation",
            subtitle: "Mindfulness practice",
            isFixed: false
        ),
        SessionItem(
            id: UUID(),
            name: "Creative Work",
            subtitle: "Art and design",
            isFixed: false
        ),
        SessionItem(
            id: UUID(),
            name: "Planning",
            subtitle: "Strategy and planning",
            isFixed: false
        ),
        SessionItem(
            id: UUID(),
            name: "Review",
            subtitle: "Reflection time",
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
            activity: "Work",
            subtitle: "Professional tasks",
            memo: "Completed the main project milestone"
        ),
        SessionRecord(
            id: "20250106_080000",
            start: Date().addingTimeInterval(-7200),
            end: Date().addingTimeInterval(-3600),
            phase: .focus,
            activity: "Study",
            subtitle: "Learning activities",
            memo: "Reviewed SwiftUI documentation"
        ),
        SessionRecord(
            id: "20250106_070000",
            start: Date().addingTimeInterval(-10800),
            end: Date().addingTimeInterval(-7200),
            phase: .focus,
            activity: "Read",
            subtitle: "Reading time",
            memo: "Finished chapter 5 of the book"
        )
    ]

    // MARK: - Environment Values

    /// プレビュー用の環境値
    struct EnvironmentValues {
        /// 通常の環境値
        static let normal = EnvironmentValues()

        /// アクセシビリティ対応の環境値
        static let accessibility = EnvironmentValues(
            sizeCategory: .accessibilityExtraExtraExtraLarge,
            colorScheme: .dark,
            accessibilityReduceMotion: true
        )

        /// ダークモード
        static let darkMode = EnvironmentValues(colorScheme: .dark)

        /// ライトモード
        static let lightMode = EnvironmentValues(colorScheme: .light)

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
    func previewEnvironment(_ values: PreviewData.EnvironmentValues) -> some View {
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
        previewEnvironment(PreviewData.EnvironmentValues.accessibility)
            .previewDisplayName("Accessibility")
    }

    /// ダーク/ライトモードのプレビュー
    func previewColorSchemes() -> some View {
        Group {
            self
                .previewEnvironment(PreviewData.EnvironmentValues.lightMode)
                .previewDisplayName("Light Mode")

            self
                .previewEnvironment(PreviewData.EnvironmentValues.darkMode)
                .previewDisplayName("Dark Mode")
        }
    }
}
