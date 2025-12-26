import XCTest
@testable import TsukiUsagi

final class TimerPersistenceTests: XCTestCase {
    @MainActor
    func testSaveState() async {
        let mock = MockDependencyContainer()
        let vm = mock.timerVM

        // Simulate a running session then stop
        await vm.startTimer()
        await vm.stopTimer()

        // Save current state via ViewModel API - should not throw
        vm.saveTimerState()

        // Verify state is in expected condition after stop
        // runState を使用（isRunning はbindingの伝播遅延の可能性あり）
        XCTAssertEqual(vm.runState, .idle)
    }
}
