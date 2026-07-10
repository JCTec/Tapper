import XCTest

final class AppStoreScreenshotUITests: XCTestCase {
  private var app: XCUIApplication!
  private var screenshotDirectory: URL!

  override func setUpWithError() throws {
    try super.setUpWithError()

    continueAfterFailure = false

    self.app = XCUIApplication()
    self.app.launchArguments = ["-ShowcaseData"]

    let directoryPath = ProcessInfo.processInfo.environment["APPSTORE_SCREENSHOT_DIR"]
      ?? NSTemporaryDirectory()
    self.screenshotDirectory = URL(fileURLWithPath: directoryPath, isDirectory: true)
  }

  override func tearDownWithError() throws {
    self.app = nil
    self.screenshotDirectory = nil

    try super.tearDownWithError()
  }

  func testCaptureAppStoreScreenshots() throws {
    self.app.launch()

    XCTAssertTrue(self.app.staticTexts["Tappers"].waitForExistence(timeout: 5.0))
    try self.captureScreenshot(named: "01-dashboard")

    try self.openTapper(named: "Push-ups")
    try self.captureScreenshot(named: "02-push-ups")
    self.app.buttons["closeTapperButton"].tap()

    try self.openTapper(named: "Sit-ups")
    try self.captureScreenshot(named: "03-sit-ups")
    self.app.buttons["closeTapperButton"].tap()

    try self.openTapper(named: "Squats")
    try self.captureScreenshot(named: "04-squats")
  }

  private func openTapper(named name: String) throws {
    let openButton = self.app.buttons["openTapper-\(name)"]
    XCTAssertTrue(openButton.waitForExistence(timeout: 5.0))
    openButton.tap()

    let nameLabel = self.app.staticTexts["fullTapperName"]
    XCTAssertTrue(nameLabel.waitForExistence(timeout: 5.0))
    XCTAssertEqual(nameLabel.label, name)
  }

  private func captureScreenshot(named name: String) throws {
    try FileManager.default.createDirectory(
      at: self.screenshotDirectory,
      withIntermediateDirectories: true
    )

    let screenshot = XCUIScreen.main.screenshot()
    let outputURL = self.screenshotDirectory.appendingPathComponent("\(name).png")
    try screenshot.pngRepresentation.write(to: outputURL, options: .atomic)
    print("Saved App Store screenshot: \(outputURL.path)")

    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = name
    attachment.lifetime = .keepAlways
    self.add(attachment)
  }
}
