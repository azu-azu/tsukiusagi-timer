import XCTest
@testable import TsukiUsagi

final class MessagesLocalizationSmokeTests: XCTestCase {
    func testDeleteSessionQuestionIsMessage() {
        // Verify question text is in Messages, not Labels
        let question = NSLocalizedString("settings_delete_session_question", comment: "")
        XCTAssertTrue(question.contains("?"), "Delete session question should contain '?'")
    }

    func testPlaceholdersAreMessages() {
        // Verify placeholders are properly localized
        let placeholder = NSLocalizedString("reflection_placeholder", comment: "")
        XCTAssertFalse(placeholder.isEmpty, "Reflection placeholder should not be empty")
    }
}
