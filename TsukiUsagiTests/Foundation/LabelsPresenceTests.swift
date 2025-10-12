import XCTest
@testable import TsukiUsagi

final class LabelsPresenceTests: XCTestCase {
    func testReflectionLabelsExist() {
        // Verify namespace separation (NSLocalizedString comparison)
        XCTAssertEqual(Labels.Sections.reflection, NSLocalizedString("reflection_title", comment: ""))
        XCTAssertEqual(Labels.InfoRow.reflection, NSLocalizedString("history_memo_reflection", comment: ""))
    }

    func testNoQuestionMarksInLabels() {
        let allLabels = [
            Labels.Sections.sessionManagement,
            Labels.Sections.deleteSession,
            Labels.State.noRecordsForThisDay
        ]

        for label in allLabels {
            XCTAssertFalse(label.contains("?"), "Labels should not contain question marks: \(label)")
            XCTAssertFalse(label.contains("…"), "Labels should not contain ellipsis: \(label)")
            XCTAssertFalse(label.hasSuffix("."), "Labels should not end with a period: \(label)")
        }
    }
}
