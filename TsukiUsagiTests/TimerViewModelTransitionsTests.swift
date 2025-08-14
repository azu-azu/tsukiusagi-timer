import XCTest
@testable import TsukiUsagi

final class TimerViewModelTransitionsTests: XCTestCase {
    @MainActor
    func testPauseResumeStopTransitions() async {
        let mock = MockDependencyContainer()
        let vm = mock.timerVM

        // Start
        vm.startTimer(seconds: 5)
        XCTAssertTrue(vm.isRunning)

        // Pause
        vm.pauseTimer()
        XCTAssertFalse(vm.isRunning)

        // Resume
        vm.resumeTimer()
        XCTAssertTrue(vm.isRunning)

        // Stop
        vm.stopTimer()
        XCTAssertFalse(vm.isRunning)
    }
}
