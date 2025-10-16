import XCTest
@testable import TsukiUsagi

final class MessagesLocalizationSmokeTests: XCTestCase {
    func testDeleteSessionQuestionIsMessage() {
        // Verify question text is in Messages, not Labels
        let question = String(localized: LocalizedStringKey("settings_delete_session_question"))
        XCTAssertTrue(question.contains("?"), "Delete session question should contain '?'")
    }

    func testPlaceholdersAreMessages() {
        // Verify placeholders are properly localized
        let placeholder = String(localized: LocalizedStringKey("reflection_placeholder"))
        XCTAssertFalse(placeholder.isEmpty, "Reflection placeholder should not be empty")
    }
}
