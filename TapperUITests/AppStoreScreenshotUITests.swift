import XCTest

/// Captures the marketing screenshots that feed `Scripts/generate_appstore_assets.swift`.
///
/// Run it through fastlane rather than Xcode so every device in `fastlane/Snapfile`
/// is covered and the status bar is pinned:
///
///     bundle exec fastlane screenshots
///
/// Captures land in `fastlane/screenshots/en-US/<device>-<name>.png`. The names
/// here must match the `id` values in `Marketing/copy.json`.
@MainActor
final class AppStoreScreenshotUITests: XCTestCase {
  private var app: XCUIApplication!

  override func setUpWithError() throws {
    try super.setUpWithError()

    continueAfterFailure = false

    self.app = XCUIApplication()

    // Must be assigned before `setupSnapshot`, which appends fastlane's own
    // locale and `-FASTLANE_SNAPSHOT` arguments rather than replacing them.
    self.app.launchArguments = ["-ShowcaseData"]
    setupSnapshot(self.app)
  }

  override func tearDownWithError() throws {
    self.app = nil

    try super.tearDownWithError()
  }

  func testCaptureAppStoreScreenshots() throws {
    self.app.launch()

    XCTAssertTrue(self.app.staticTexts["Tappers"].waitForExistence(timeout: 5.0))
    self.captureScreenshot(named: "01-dashboard")

    try self.openTapper(named: "Push-ups")
    self.captureScreenshot(named: "02-push-ups")
    self.app.buttons["closeTapperButton"].tap()

    try self.openTapper(named: "Sit-ups")
    self.captureScreenshot(named: "03-sit-ups")
    self.app.buttons["closeTapperButton"].tap()

    try self.openTapper(named: "Squats")
    self.captureScreenshot(named: "04-squats")
  }

  private func openTapper(named name: String) throws {
    let openButton = self.app.buttons["openTapper-\(name)"]
    XCTAssertTrue(openButton.waitForExistence(timeout: 5.0))
    openButton.tap()

    let nameLabel = self.app.staticTexts["fullTapperName"]
    XCTAssertTrue(nameLabel.waitForExistence(timeout: 5.0))
    XCTAssertEqual(nameLabel.label, name)
  }

  /// Hands the shot to fastlane and also attaches it, so a CI `.xcresult`
  /// carries the captures even when the snapshot export is unavailable.
  private func captureScreenshot(named name: String) {
    snapshot(name)

    let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    self.add(attachment)
  }
}
