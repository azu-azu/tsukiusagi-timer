import XCTest
@testable import TsukiUsagi

@MainActor
final class FutureFinalFlagsTests: XCTestCase {

    func testHasRecordedEndTimeAndFutureBadgeFlags() {
        let mock = MockDependencyContainer()
        let vm = mock.timerVM

        // Given a started session
        let start = Date()
        vm._setPreviewState(startTime: start, isWorkSession: true, isRunning: false)

        // When setting a future end time (start + 10 minutes)
        let futureEnd = start.addingTimeInterval(10 * 60)
        vm.applyEditedEndTime(futureEnd)

        // Then
        XCTAssertTrue(vm.hasRecordedEndTime, "endTime != nil should gate Final visibility")
        XCTAssertTrue(vm.isFutureFinal, "Future end should be detected for badge display")
        XCTAssertEqual(vm.actualSessionMinutes, 10, "Exact 10 minutes should render as 10")
    }

    func testRoundingNearestTiesAwayFromZero() {
        let mock = MockDependencyContainer()
        let vm = mock.timerVM

        let start = Date()
        vm._setPreviewState(startTime: start, isWorkSession: true, isRunning: false)

        // 89.6s => 1.49 min => rounds to 1
        vm.applyEditedEndTime(start.addingTimeInterval(89.6))
        XCTAssertEqual(vm.actualSessionMinutes, 1)

        // 90s => 1.5 min => ties away from zero => 2
        vm.applyEditedEndTime(start.addingTimeInterval(90))
        XCTAssertEqual(vm.actualSessionMinutes, 2)

        // 0s => 0 min (allowed; UI can decide display policy)
        vm.applyEditedEndTime(start)
        XCTAssertEqual(vm.actualSessionMinutes, 0)
    }

    func testRoundingAcrossDSTBoundaryIsIntervalBased() {
        let mock = MockDependencyContainer()
        let vm = mock.timerVM

        let start = Date(timeIntervalSince1970: 1_710_000_000) // fixed point
        vm._setPreviewState(startTime: start, isWorkSession: true, isRunning: false)

        // Add 5400 seconds (90 minutes) regardless of calendar/timezone rules
        let end = start.addingTimeInterval(90 * 60)
        vm.applyEditedEndTime(end)
        XCTAssertEqual(vm.actualSessionMinutes, 90)
    }
}
