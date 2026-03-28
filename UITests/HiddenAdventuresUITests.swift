import XCTest

final class HiddenAdventuresUITests: XCTestCase {
  private let bluePoolID = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testSlice1WalkthroughCapturesScreenshots() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "walkthrough")
    let app = XCUIApplication()

    app.launchEnvironment["UITEST_START_SCREEN"] = "welcome"
    app.launch()

    assertExists(
      app.buttons["welcome.getStarted"],
      name: "welcome-get-started",
      in: app,
      screenshotDir: screenshotDir
    )
    saveScreenshot(named: "01-welcome", to: screenshotDir)

    app.buttons["welcome.getStarted"].tap()
    assertExists(
      app.buttons["profile.continue"],
      name: "profile-continue",
      in: app,
      screenshotDir: screenshotDir
    )
    saveScreenshot(named: "02-profile", to: screenshotDir)

    app.buttons["profile.continue"].tap()
    assertExists(
      app.buttons["tab.home"],
      name: "feed-home-tab",
      in: app,
      screenshotDir: screenshotDir
    )
    saveScreenshot(named: "03-feed", to: screenshotDir)

    app.buttons["tab.explore"].tap()
    assertExists(
      app.buttons["map.card.\(bluePoolID)"],
      name: "map-card",
      in: app,
      screenshotDir: screenshotDir
    )
    saveScreenshot(named: "04-map", to: screenshotDir)

    let mapCard = app.buttons["map.card.\(bluePoolID)"]
    assertExists(mapCard, name: "map-card-tap", in: app, screenshotDir: screenshotDir)
    mapCard.tap()

    assertExists(
      app.buttons["detail.back"],
      name: "detail-back",
      in: app,
      screenshotDir: screenshotDir
    )
    saveScreenshot(named: "05-detail", to: screenshotDir)

    app.buttons["detail.back"].tap()
    assertExists(
      app.buttons["map.card.\(bluePoolID)"],
      name: "map-return",
      in: app,
      screenshotDir: screenshotDir
    )
    saveScreenshot(named: "06-map-return", to: screenshotDir)
  }

  func testDirectLaunchGalleryCapturesScreenshots() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "gallery")

    try launchAndCapture(
      named: "welcome",
      environment: ["UITEST_START_SCREEN": "welcome"],
      screenshotDir: screenshotDir,
      expectedIdentifier: "welcome.getStarted"
    )

    try launchAndCapture(
      named: "profile",
      environment: ["UITEST_START_SCREEN": "profile"],
      screenshotDir: screenshotDir,
      expectedIdentifier: "profile.continue"
    )

    try launchAndCapture(
      named: "explore-feed",
      environment: ["UITEST_START_SCREEN": "explore-feed"],
      screenshotDir: screenshotDir,
      expectedIdentifier: "tab.home"
    )

    try launchAndCapture(
      named: "explore-map",
      environment: ["UITEST_START_SCREEN": "explore-map"],
      screenshotDir: screenshotDir,
      expectedIdentifier: "map.card.\(bluePoolID)"
    )

    try launchAndCapture(
      named: "detail",
      environment: [
        "UITEST_START_SCREEN": "detail",
        "UITEST_DETAIL_ID": bluePoolID
      ],
      screenshotDir: screenshotDir,
      expectedIdentifier: "detail.back"
    )
  }

  private func launchAndCapture(
    named name: String,
    environment: [String: String],
    screenshotDir: URL,
    expectedIdentifier: String
  ) throws {
    let app = XCUIApplication()
    environment.forEach { app.launchEnvironment[$0.key] = $0.value }
    app.launch()
    assertExists(
      app.buttons[expectedIdentifier],
      name: name,
      in: app,
      screenshotDir: screenshotDir
    )
    saveScreenshot(named: name, to: screenshotDir)
    app.terminate()
  }

  private func preparedScreenshotDirectory(named name: String) throws -> URL {
    let rootPath = ProcessInfo.processInfo.environment["UITEST_SCREENSHOT_DIR"]
      ?? "/tmp/hidden_adventures_ui_tests"
    let directory = URL(fileURLWithPath: rootPath).appendingPathComponent(name, isDirectory: true)

    try FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true,
      attributes: nil
    )
    print("Saving screenshots to \(directory.path)")
    return directory
  }

  private func saveScreenshot(named name: String, to directory: URL) {
    let screenshot = XCUIScreen.main.screenshot()
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)

    let destination = directory.appendingPathComponent("\(name).png")
    do {
      try screenshot.pngRepresentation.write(to: destination)
      print("Saved screenshot \(destination.path)")
    } catch {
      XCTFail("Failed to write screenshot \(name): \(error)")
    }
  }

  private func assertExists(
    _ element: XCUIElement,
    name: String,
    in app: XCUIApplication,
    screenshotDir: URL
  ) {
    guard element.waitForExistence(timeout: 5) else {
      print("Failed to find element for \(name)")
      print(app.debugDescription)
      saveScreenshot(named: "failure-\(name)", to: screenshotDir)
      XCTFail("Missing element \(name)")
      return
    }
  }
}
