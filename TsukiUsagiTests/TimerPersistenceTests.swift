import XCTest
@testable import TsukiUsagi

final class TimerPersistenceTests: XCTestCase {
    @MainActor
    func testSaveRestoreState() async {
        let mock = MockDependencyContainer()
        let vm = mock.timerVM

        // Simulate a running session then stop
        vm.startTimer(seconds: 25 * 60)
        vm.stopTimer()

        // Save current state via ViewModel API
        vm.saveTimerState()

        // Restore into a fresh VM instance using same underlying services
        let vm2 = TimerViewModel(
            engine: mock.timerEngine,
            notificationService: mock.notificationService,
            hapticService: mock.hapticService,
            historyService: mock.historyService,
            persistenceManager: mock.persistenceManager,
            formatter: mock.formatter
        )
        vm2.restoreTimerState()

        XCTAssertEqual(vm2.timeRemaining, vm.timeRemaining)
        XCTAssertEqual(vm2.isRunning, vm.isRunning)
        XCTAssertEqual(vm2.isWorkSession, vm.isWorkSession)
    }
}
