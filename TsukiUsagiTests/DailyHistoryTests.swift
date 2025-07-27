import XCTest
@testable import TsukiUsagi

final class DailyHistoryTests: XCTestCase {

    func testDailyHistoryInitialization() {
        let date = Date()
        let activities = ["Programming": 120, "Reading": 30]

        let history = DailyHistory(
            date: date,
            totalMinutes: 150,
            sessionCount: 2,
            activities: activities,
            hasRecords: true
        )

        XCTAssertEqual(history.totalMinutes, 150)
        XCTAssertEqual(history.sessionCount, 2)
        XCTAssertEqual(history.activities.count, 2)
        XCTAssertTrue(history.hasRecords)
    }

    func testTopActivities() {
        let activities = ["Programming": 120, "Reading": 30, "Writing": 45, "Exercise": 60]
        let history = DailyHistory(
            date: Date(),
            totalMinutes: 255,
            sessionCount: 4,
            activities: activities,
            hasRecords: true
        )

        let topActivities = history.topActivities
        XCTAssertEqual(topActivities.count, 3)
        XCTAssertEqual(topActivities[0], "Programming")
        XCTAssertEqual(topActivities[1], "Exercise")
        XCTAssertEqual(topActivities[2], "Writing")
    }

    func testActivityIntensity() {
        let testCases = [
            (0, ActivityIntensity.none),
            (15, ActivityIntensity.low),
            (30, ActivityIntensity.low),
            (60, ActivityIntensity.medium),
            (90, ActivityIntensity.medium),
            (120, ActivityIntensity.high)
        ]

        for (minutes, expectedIntensity) in testCases {
            let history = DailyHistory(
                date: Date(),
                totalMinutes: minutes,
                sessionCount: 1,
                activities: ["Test": minutes],
                hasRecords: minutes > 0
            )

            XCTAssertEqual(history.activityIntensity, expectedIntensity)
        }
    }

    func testPrimaryActivity() {
        let activities = ["Programming": 120, "Reading": 30]
        let history = DailyHistory(
            date: Date(),
            totalMinutes: 150,
            sessionCount: 2,
            activities: activities,
            hasRecords: true
        )

        XCTAssertEqual(history.primaryActivity, "Programming")
    }
}
