import XCTest

final class TapperUITests: XCTestCase {
  private var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false

    self.app = XCUIApplication()
    self.app.launchArguments = ["-UITesting"]
  }

  override func tearDownWithError() throws {
    self.app = nil
  }

  func testCreateCountResetAndDeleteTapper() throws {
    self.app.launch()

    XCTAssertTrue(self.app.staticTexts["No Tappers"].waitForExistence(timeout: 5.0))

    self.app.buttons["addTapperButton"].tap()

    let nameField = self.app.textFields["tapperNameField"]
    XCTAssertTrue(nameField.waitForExistence(timeout: 5.0))
    nameField.tap()
    nameField.typeText("Workout")

    self.app.buttons["saveTapperButton"].tap()

    let openButton = self.app.buttons["openTapper-Workout"]
    XCTAssertTrue(openButton.waitForExistence(timeout: 5.0))

    self.app.buttons["increment-Workout"].tap()
    self.app.buttons["decrement-Workout"].tap()
    self.app.buttons["increment-Workout"].tap()

    self.app.buttons["openTapper-Workout"].tap()

    let fullCounterValue = self.app.staticTexts["fullCounterValue"]
    XCTAssertTrue(fullCounterValue.waitForExistence(timeout: 5.0))
    self.wait(for: fullCounterValue, toHaveLabel: "1")

    self.app.buttons["fullIncrementButton"].tap()
    self.wait(for: fullCounterValue, toHaveLabel: "2")

    self.app.buttons["resetTapperButton"].tap()
    self.app.buttons["confirmResetTapperButton"].firstMatch.tap()
    self.wait(for: fullCounterValue, toHaveLabel: "0")

    self.app.buttons["editTapperButton"].tap()
    XCTAssertTrue(self.app.buttons["deleteTapperButton"].waitForExistence(timeout: 5.0))
    self.app.buttons["deleteTapperButton"].tap()
    self.app.buttons["confirmDeleteTapperButton"].firstMatch.tap()

    XCTAssertTrue(self.app.staticTexts["No Tappers"].waitForExistence(timeout: 5.0))
  }

  func testLaunchPerformance() throws {
    if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
      measure(metrics: [XCTApplicationLaunchMetric()]) {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()
      }
    }
  }

  private func wait(for element: XCUIElement, toHaveLabel label: String, timeout: TimeInterval = 3.0) {
    let predicate = NSPredicate(format: "label == %@", label)
    expectation(for: predicate, evaluatedWith: element)
    waitForExpectations(timeout: timeout)
  }
}
