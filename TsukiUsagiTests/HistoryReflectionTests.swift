import XCTest
@testable import TsukiUsagi

@MainActor
final class HistoryReflectionTests: XCTestCase {
    private func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func removeTempDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    func testLegacyMigration_migratesReflectionRowsOnce() throws {
        let tempDir = try makeTempDirectory()
        defer { removeTempDirectory(tempDir) }

        let legacyDates = makeLegacySessionDates()
        let legacyURL = tempDir.appendingPathComponent("history.json")
        try writeLegacyHistoryFile(
            to: legacyURL,
            start: legacyDates.start,
            mid: legacyDates.mid,
            end: legacyDates.end
        )

        let store = HistoryStore(baseURL: tempDir)

        let snapshot = store.load()
        XCTAssertEqual(snapshot.migrationVersion, 1)
        XCTAssertEqual(snapshot.sessions.count, 1)
        XCTAssertEqual(snapshot.sessions.first?.sessionName, "Work")

        let dayKey = HistoryDateKey.dayKey(for: legacyDates.start)
        let reflection = snapshot.reflections[dayKey]
        XCTAssertEqual(reflection?.text, "First memo\n\nSecond memo")
        XCTAssertEqual(reflection?.isPendingSave, false)

        // Migration should be idempotent.
        let secondLoad = store.load()
        XCTAssertEqual(secondLoad.sessions.count, 1)
        XCTAssertEqual(secondLoad.reflections.count, 1)
        XCTAssertEqual(secondLoad.reflections[dayKey]?.text, "First memo\n\nSecond memo")
        XCTAssertTrue(secondLoad.sessions.allSatisfy { $0.sessionName != "Reflection" })
    }

    func testDayKey_TimezoneAndDST_IsStable() throws {
        let originalTimeZone = TimeZone.current
        let losAngeles = TimeZone(identifier: "America/Los_Angeles")!
        TimeZone.ReferenceType.default = losAngeles
        defer { TimeZone.ReferenceType.default = originalTimeZone }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = losAngeles

        let early = calendar.date(from: DateComponents(year: 2024, month: 3, day: 10, hour: 1, minute: 30))!
        let late = calendar.date(from: DateComponents(year: 2024, month: 3, day: 10, hour: 3, minute: 30))!

        let keyEarly = HistoryDateKey.dayKey(for: early)
        let keyLate = HistoryDateKey.dayKey(for: late)

        XCTAssertEqual(keyEarly, keyLate, "Day key should remain stable across DST transition within same local day")

        let nextDay = calendar.date(from: DateComponents(year: 2024, month: 3, day: 11, hour: 8))!
        let keyNextDay = HistoryDateKey.dayKey(for: nextDay)
        XCTAssertNotEqual(keyEarly, keyNextDay)
    }

    func testSummaryCard_Heuristics_PicksDominantAndLatestDescription() throws {
        let tempDir = try makeTempDirectory()
        defer { removeTempDirectory(tempDir) }

        let store = HistoryStore(baseURL: tempDir)
        let historyVM = HistoryViewModel(store: store)
        let provider = DailyTimelineDataProvider()
        let baseDay = Date()

        seedWorkAndStudySessions(on: baseDay, into: historyVM)

        let summary = provider.makeDaySummary(historyVM: historyVM, targetDate: baseDay)
        XCTAssertEqual(summary.sessionName, "Work")
        XCTAssertEqual(summary.tasks.count, 2)
        XCTAssertEqual(summary.tasks.first?.title, "Latest")
        XCTAssertEqual(Int(summary.tasks.first?.duration ?? 0), 5400)
        XCTAssertEqual(summary.tasks.last?.title, "Initial")
        XCTAssertEqual(Int(summary.tasks.last?.duration ?? 0), 3600)
        XCTAssertEqual(Int(summary.sessionDuration), 3600 + 5400)
        XCTAssertEqual(Int(summary.total), 3600 + 5400 + 1200)
    }

    func testInlineReflection_AutosaveAndRetry_WorksOffline() async throws {
        let tempDir = try makeTempDirectory()
        defer { removeTempDirectory(tempDir) }

        let store = HistoryStore(baseURL: tempDir)
        let historyVM = HistoryViewModel(store: store)
        let targetDate = Date()

        // Remove directory to force initial save failure.
        try FileManager.default.removeItem(at: tempDir)

        let failureExpectation = expectation(description: "Save should fail")
        let observer = NotificationCenter.default.addObserver(
            forName: Notification.Name("HistorySaveFailed"),
            object: nil,
            queue: .main
        ) { _ in
            failureExpectation.fulfill()
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        historyVM.updateReflection(for: targetDate, text: "Offline note")
        await fulfillment(of: [failureExpectation], timeout: 2.0)

        let dayKey = HistoryDateKey.dayKey(for: targetDate)
        XCTAssertEqual(historyVM.reflection(for: dayKey)?.isPendingSave, true)
        XCTAssertNotNil(historyVM.reflectionSaveError)

        // Recreate directory and retry.
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let savedExpectation = expectation(description: "Reflection saved after retry")
        Task {
            while true {
                try await Task.sleep(nanoseconds: 50_000_000)
                if let reflection = historyVM.reflection(for: dayKey),
                   !reflection.isPendingSave,
                   historyVM.reflectionSaveError == nil {
                    savedExpectation.fulfill()
                    break
                }
            }
        }

        historyVM.retrySaveReflection()
        await fulfillment(of: [savedExpectation], timeout: 3.0)
        XCTAssertEqual(historyVM.reflection(for: dayKey)?.text, "Offline note")
    }

    func testAtomicSaveProducesValidJSON() throws {
        let tempDir = try makeTempDirectory()
        defer { removeTempDirectory(tempDir) }

        let store = HistoryStore(baseURL: tempDir)
        let historyVM = HistoryViewModel(store: store)
        let targetDate = Date()

        historyVM.updateReflection(for: targetDate, text: "Persistent memo")

        // Wait briefly for async save.
        let expectation = XCTestExpectation(description: "Wait for save")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)

        // Reload from disk and ensure decoding succeeds.
        let reloaded = store.load()
        let dayKey = HistoryDateKey.dayKey(for: targetDate)

        XCTAssertEqual(reloaded.reflections[dayKey]?.text, "Persistent memo")
    }
}

private extension HistoryReflectionTests {
    func makeLegacySessionDates() -> LegacyDates {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.date(from: DateComponents(year: 2024, month: 3, day: 3, hour: 9, minute: 0))!
        let mid = calendar.date(from: DateComponents(year: 2024, month: 3, day: 3, hour: 12, minute: 0))!
        let end = calendar.date(from: DateComponents(year: 2024, month: 3, day: 3, hour: 14, minute: 0))!
        return LegacyDates(start: start, mid: mid, end: end)
    }

    func writeLegacyHistoryFile(to url: URL, start: Date, mid: Date, end: Date) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let legacyRecords = legacyReflectionRecords(start: start, mid: mid, end: end)
        let legacyData = try encoder.encode(legacyRecords)
        try legacyData.write(to: url)
    }

    func legacyReflectionRecords(start: Date, mid: Date, end: Date) -> [SessionRecord] {
        [
            SessionRecord(
                id: "reflection-1",
                start: start,
                end: start.addingTimeInterval(600),
                phase: .focus,
                sessionName: "Reflection",
                task: "",
                memo: "First memo",
                completedSilently: nil
            ),
            SessionRecord(
                id: "reflection-2",
                start: mid,
                end: mid.addingTimeInterval(300),
                phase: .focus,
                sessionName: "Reflection",
                task: "",
                memo: "Second memo",
                completedSilently: nil
            ),
            SessionRecord(
                id: "work-1",
                start: end,
                end: end.addingTimeInterval(1800),
                phase: .focus,
                sessionName: "Work",
                task: "Deep work",
                memo: nil,
                completedSilently: nil
            )
        ]
    }

    func seedWorkAndStudySessions(on baseDay: Date, into historyVM: HistoryViewModel) {
        let calendar = Calendar.current
        let workMorning = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: baseDay)!
        let workNoon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: baseDay)!
        let study = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: baseDay)!

        let sessions = [
            SessionRecord(
                id: "work-1",
                start: workMorning,
                end: workMorning.addingTimeInterval(3600),
                phase: .focus,
                sessionName: "Work",
                task: "Initial",
                memo: nil,
                completedSilently: nil
            ),
            SessionRecord(
                id: "work-2",
                start: workNoon,
                end: workNoon.addingTimeInterval(5400),
                phase: .focus,
                sessionName: "Work",
                task: "Latest",
                memo: nil,
                completedSilently: nil
            ),
            SessionRecord(
                id: "study-1",
                start: study,
                end: study.addingTimeInterval(1200),
                phase: .focus,
                sessionName: "Study",
                task: "Reading",
                memo: nil,
                completedSilently: nil
            )
        ]

        sessions.forEach { historyVM.addRecord($0) }
    }
}

private struct LegacyDates {
    let start: Date
    let mid: Date
    let end: Date
}
