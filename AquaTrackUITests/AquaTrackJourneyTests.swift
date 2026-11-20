import XCTest

final class AquaTrackJourneyTests: XCTestCase {
    func testQuickAndCustomLoggingGoalEditingDeletionAndRelaunch() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let total = app.staticTexts["water.total"]
        XCTAssertTrue(total.waitForExistence(timeout: 5))
        let start = amount(in: total.label)

        app.buttons["water.add.8"].tap()
        XCTAssertEqual(amount(in: total.label), start + 8)

        let customAmount = app.textFields["water.amount"]
        customAmount.tap()
        XCTAssertFalse(app.buttons["water.add.custom"].isEnabled)
        customAmount.typeText("2.5")
        app.buttons["water.add.custom"].tap()
        XCTAssertEqual(amount(in: total.label), start + 10.5)

        let row = app.staticTexts["2.5 oz"].firstMatch
        if !row.isHittable { app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft()
        let delete = app.buttons["Delete"]
        if delete.exists { delete.tap() }
        if !total.isHittable { app.swipeDown() }
        XCTAssertEqual(amount(in: total.label), start + 8)

        app.buttons["water.settings"].tap()
        let goal = app.textFields["water.goal.input"]
        XCTAssertTrue(goal.waitForExistence(timeout: 5))
        goal.tap()
        let previous = goal.value as? String ?? ""
        goal.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: previous.count))
        goal.typeText("80")
        app.buttons["water.goal.save"].tap()

        app.terminate()
        app.launch()
        let goalLabel = app.staticTexts["water.goal"]
        XCTAssertTrue(goalLabel.waitForExistence(timeout: 5))
        XCTAssertTrue(goalLabel.label.contains("80"))
        XCTAssertEqual(amount(in: total.label), start + 8)
    }

    func testListingScreenshot() {
        let app = XCUIApplication()
        app.launch()
        let total = app.staticTexts["water.total"]
        XCTAssertTrue(total.waitForExistence(timeout: 5))
        if amount(in: total.label) < 24 {
            app.buttons["water.add.16"].tap()
            app.buttons["water.add.12"].tap()
            app.buttons["water.add.8"].tap()
        }

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "AquaTrack-DailyLog"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    private func amount(in label: String) -> Double {
        let parsed = label.components(separatedBy: .whitespaces).first ?? ""
        return Double(parsed.replacingOccurrences(of: ",", with: "")) ?? -1
    }
}
