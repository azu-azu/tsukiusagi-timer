import XCTest
@testable import TsukiUsagi

// MARK: - Spies

final class SpyNotificationService: PhaseNotificationServiceable {
    enum Call: Equatable {
        case start
        case scheduleEnd(Int, PomodoroPhase)
        case cancelEnd
        case phaseChange(PomodoroPhase)
        case cancelAll
        case finalizeWork
        case finalizeBreak
    }
    private(set) var calls: [Call] = []

    func sendStartNotification() { calls.append(.start) }
    func cancelNotification() { calls.append(.cancelAll) }
    func scheduleSessionEndNotification(after seconds: Int, phase: PomodoroPhase) {
        calls.append(.scheduleEnd(seconds, phase))
    }
    func sendPhaseChangeNotification(for phase: PomodoroPhase) { calls.append(.phaseChange(phase)) }
    func cancelSessionEndNotification() { calls.append(.cancelEnd) }
    func finalizeWorkPhase() { calls.append(.finalizeWork) }
    func finalizeBreakPhase() { calls.append(.finalizeBreak) }
}

final class SpyHistoryService: SessionHistoryServiceable {
    private(set) var added: [AddSessionParameters] = []
    func add(parameters: AddSessionParameters) { added.append(parameters) }
}

// MARK: - Tests

@MainActor
final class NotificationAndHistorySpiesTests: XCTestCase {
    func testBackgroundForegroundSchedulingCalls() throws {
        // Given
        let mock = MockDependencyContainer()
        let spyNotification = SpyNotificationService()
        let vm = TimerViewModel(
            engine: mock.timerEngine,
            notificationService: spyNotification,
            hapticService: mock.hapticService,
            historyService: mock.historyService,
            persistenceManager: mock.persistenceManager,
            formatter: mock.formatter
        )

        // When: start and go background immediately
        vm.startTimer(seconds: 120)
        vm.appDidEnterBackground()
        vm.appWillEnterForeground()

        // Then
        // Expect schedule followed by cancel
        XCTAssertGreaterThanOrEqual(spyNotification.calls.count, 2)
        // Find first schedule and first cancel occurrence order (with XCTUnwrap)
        let firstScheduleIndex = try XCTUnwrap(
            spyNotification.calls.firstIndex { if case .scheduleEnd = $0 { return true } else { return false } },
            "scheduleEnd が一度も呼ばれていない"
        )
        let firstCancelIndex = try XCTUnwrap(
            spyNotification.calls.firstIndex { $0 == .cancelEnd },
            "cancelEnd が一度も呼ばれていない"
        )
        XCTAssertLessThan(firstScheduleIndex, firstCancelIndex)

        // Validate schedule parameters
        if case let .scheduleEnd(seconds, phase)? = spyNotification.calls.first(where: {
            if case .scheduleEnd = $0 { return true } else { return false }
        }) {
            XCTAssertEqual(phase, .focus)
            XCTAssertGreaterThan(seconds, 0)
        } else {
            XCTFail("No scheduleEnd call recorded")
        }

        // Negative assertion: finalizeBreak should not be called in background flow
        XCTAssertFalse(
            spyNotification.calls.contains { if case .finalizeBreak = $0 { return true } else { return false } },
            "背景遷移の流れで finalizeBreak は呼ばれないはず"
        )

        // Call count assertion: scheduleEnd should be exactly once in this flow
        XCTAssertEqual(
            spyNotification.calls.filter { if case .scheduleEnd = $0 { return true } else { return false } }.count,
            1,
            "scheduleEnd は1回だけのはず"
        )
    }

    func testForceFinishSendsCorrectHistoryParameters() {
        // Given
        let engine = MockTimerEngine()
        let spyNotification = SpyNotificationService()
        let spyHistory = SpyHistoryService()
        let persistence = TimerPersistenceManager()
        let formatter = TimeFormatterUtil()
        let haptic = HapticService()

        let vm = TimerViewModel(
            engine: engine,
            notificationService: spyNotification,
            hapticService: haptic,
            historyService: spyHistory,
            persistenceManager: persistence,
            formatter: formatter
        )

        // Set a valid startTime to enable history write path
        let start = Date().addingTimeInterval(-180)
        vm._setPreviewState(startTime: start, isWorkSession: true, isRunning: true)

        // When
        vm.forceFinishWorkSession()

        // Then
        XCTAssertEqual(spyHistory.added.count, 1)
        guard let params = spyHistory.added.first else { return }
        XCTAssertEqual(params.phase, .focus)
        XCTAssertGreaterThan(params.end, params.start)
        XCTAssertEqual(params.activity, vm.activityLabel)
        XCTAssertEqual(params.subtitle ?? "", vm.subtitleLabel)
    }
}
