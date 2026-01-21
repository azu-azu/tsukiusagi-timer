import XCTest
@testable import TsukiUsagi

// MARK: - Spies

final class SpyNotificationService: PhaseNotificationServiceable {
    enum Call: Equatable {
        case start
        case schedulePhase(PomodoroPhase)
        case cancelEnd
        case phaseChange(PomodoroPhase)
        case cancelAll
        case finalizeWork
        case finalizeBreak
    }
    private(set) var calls: [Call] = []

    func sendStartNotification() { calls.append(.start) }
    func cancelSessionEnd(for phase: PomodoroPhase) { calls.append(.cancelEnd) }
    func cancelSessionEndSafely(for completedPhase: PomodoroPhase) { calls.append(.cancelEnd) }
    func scheduleSessionEndNotification(after seconds: Int, phase: PomodoroPhase) {
        calls.append(.schedulePhase(phase))
    }
    func sendPhaseChangeNotification(for phase: PomodoroPhase) { calls.append(.phaseChange(phase)) }
    func cancelSessionEndNotification() { calls.append(.cancelEnd) }
    func finalizeWorkPhase() { calls.append(.finalizeWork) }
    func finalizeBreakPhase() { calls.append(.finalizeBreak) }
    func scheduleSessionEndNotification(at endAt: Date, phase: PomodoroPhase, timeSensitive: Bool) {
        calls.append(.schedulePhase(phase))
    }
    func rescheduleEnd(at endAt: Date, phase: PomodoroPhase, timeSensitive: Bool) {
        calls.append(.schedulePhase(phase))
    }
    func scheduleChainedSessionEnds(workEndAt: Date, breakEndAt: Date, timeSensitive: Bool) {
        calls.append(.schedulePhase(.breakTime))
        calls.append(.schedulePhase(.focus))
    }
    func ensureFocusAt(breakEndAt: Date, timeSensitive: Bool) {
        calls.append(.schedulePhase(.focus))
    }
    func cancelSessionEndAll() {
        calls.append(.cancelAll)
    }
    func ensureAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        completion(true)
    }
}

final class SpyHistoryService: SessionHistoryServiceable {
    private(set) var added: [AddSessionParameters] = []
    func add(parameters: AddSessionParameters) { added.append(parameters) }
}

// MARK: - Tests

@MainActor
final class NotificationAndHistorySpiesTests: XCTestCase {
    func testBackgroundForegroundSchedulingCalls() async throws {
        // Given
        let mock = MockDependencyContainer()
        let spyNotification = SpyNotificationService()
        let vm = TimerViewModel(
            engine: mock.timerEngine,
            notificationService: spyNotification,
            hapticService: mock.hapticService,
            historyService: mock.historyVM,
            persistenceManager: mock.persistenceManager,
            formatter: mock.formatter
        )

        // When: start and go background immediately
        await vm.startTimer()
        vm.appDidEnterBackground()
        vm.appWillEnterForeground()

        // Then
        // 最低限の検証: startTimer時にscheduleChainedが呼ばれる（breakTimeとfocusの2つ）
        // またはensureFocusAtが呼ばれる
        let scheduleCount = spyNotification.calls.filter {
            if case .schedulePhase = $0 { return true } else { return false }
        }.count
        XCTAssertGreaterThanOrEqual(scheduleCount, 1, "schedulePhase は少なくとも1回呼ばれるはず。calls: \(spyNotification.calls)")

        // Negative assertion: finalizeBreak should not be called in background flow
        XCTAssertFalse(
            spyNotification.calls.contains { if case .finalizeBreak = $0 { return true } else { return false } },
            "背景遷移の流れで finalizeBreak は呼ばれないはず"
        )
    }

    func testForceFinishSendsCorrectHistoryParameters() async {
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
        await vm.forceFinish()

        // Then
        XCTAssertEqual(spyHistory.added.count, 1)
        guard let params = spyHistory.added.first else { return }
        XCTAssertEqual(params.phase, .focus)
        XCTAssertGreaterThan(params.end, params.start)
        XCTAssertEqual(params.sessionName, vm.activityLabel)
        XCTAssertEqual(params.task ?? "", vm.taskLabel)
    }
}
