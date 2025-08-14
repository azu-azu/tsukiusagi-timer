import XCTest
@testable import TsukiUsagi
import Combine

final class TimerViewModelTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    @MainActor
    func testSecondsTick_WithMockEngine() async {
        let mock = MockDependencyContainer()
        let vm = mock.timerVM

        var received: [Int] = []
        let exp = expectation(description: "ticks 3")
        vm.$timeRemaining
            .dropFirst()
            .sink { v in
                received.append(v)
                if received.count == 3 { exp.fulfill() }
            }
            .store(in: &cancellables)

        // モックエンジンはstartコールで即時に3回tickを流す
        mock.timerEngine.start(seconds: 10)
        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(received.count, 3)
    }
}
