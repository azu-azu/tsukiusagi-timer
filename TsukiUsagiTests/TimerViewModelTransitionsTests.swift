import XCTest
@testable import TsukiUsagi

final class TimerViewModelTransitionsTests: XCTestCase {
    @MainActor
    func testPauseResumeStopTransitions() async {
        let mock = MockDependencyContainer()
        let vm = mock.timerVM

        // Start
        await vm.startTimer()
        // runState を使用（isRunning はbindingの伝播遅延の可能性あり）
        XCTAssertEqual(vm.runState, .running, "Start failed: runState=\(vm.runState)")

        // Pause
        await vm.pauseTimer()
        XCTAssertEqual(vm.runState, .paused, "Pause failed: runState=\(vm.runState)")

        // Resume
        await vm.resumeTimer()
        XCTAssertEqual(vm.runState, .running, "Resume failed: runState=\(vm.runState)")

        // Stop
        await vm.stopTimer()
        XCTAssertEqual(vm.runState, .idle, "Stop failed: runState=\(vm.runState)")
    }
}
