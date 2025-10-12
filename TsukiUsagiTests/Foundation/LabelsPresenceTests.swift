import XCTest
@testable import TsukiUsagi

final class LabelsPresenceTests: XCTestCase {
    func testReflectionLabelsExist() {
        // Verify namespace separation (non-localized literals)
        XCTAssertEqual(Labels.Sections.reflection, "Reflection")
        XCTAssertEqual(Labels.InfoRow.reflection, "Reflection")
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
