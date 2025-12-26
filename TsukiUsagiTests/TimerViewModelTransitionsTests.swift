import XCTest
@testable import TsukiUsagi

final class TimerViewModelTransitionsTests: XCTestCase {
    @MainActor
    func testPauseResumeStopTransitions() async {
        let mock = MockDependencyContainer()
        let vm = mock.timerVM

        // Start
        await vm.startTimer()
        XCTAssertTrue(vm.isRunning)

        // Pause
        await vm.pauseTimer()
        XCTAssertFalse(vm.isRunning)

        // Resume
        await vm.resumeTimer()
        XCTAssertTrue(vm.isRunning)

        // Stop
        await vm.stopTimer()
        XCTAssertFalse(vm.isRunning)
    }
}
