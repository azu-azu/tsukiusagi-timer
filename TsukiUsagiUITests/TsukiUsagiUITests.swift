//
//  TsukiUsagiUITests.swift
//  TsukiUsagiUITests
//
//  Created by azu-azu on 2025/06/11.
//

import XCTest

final class TsukiUsagiUITests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it's important to set the initial state - such as interface orientation -
        // required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testReflectionSheetOpensFromDailyTimeline() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to History tab if needed
        // Assuming default opens on main where History is accessible

        // Try to find the expand button; fallback to tapping editor if present
        let expandButton = app.buttons["open_reflection_sheet_button"]
        if expandButton.waitForExistence(timeout: 3) {
            expandButton.tap()
        } else {
            let editor = app.textViews["history_detail_reflection_editor"]
            if editor.waitForExistence(timeout: 2) {
                editor.tap()
            }
        }

        // Verify sheet editor appears
        let sheetEditor = app.textViews["large_text_editor_sheet_editor"]
        XCTAssertTrue(sheetEditor.waitForExistence(timeout: 3))

        // Close the sheet
        let closeButton = app.buttons["large_text_editor_sheet_close"]
        if closeButton.exists { closeButton.tap() }
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
