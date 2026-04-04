import XCTest

final class HiddenAdventuresUITests: XCTestCase {
  private let eagleID = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
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
    assertExists(
      app.buttons["welcome.signIn"],
      name: "welcome-sign-in",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["welcome.brandTitle"],
      name: "welcome-brand-title",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["welcome.headline"],
      name: "welcome-headline",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["welcome.legal"],
      name: "welcome-legal",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["welcome.subheadline"],
      name: "welcome-subheadline",
      in: app,
      screenshotDir: screenshotDir
    )
    assertHittable(
      app.buttons["welcome.getStarted"],
      name: "welcome-get-started",
      in: app,
      screenshotDir: screenshotDir
    )
    assertHittable(
      app.buttons["welcome.signIn"],
      name: "welcome-sign-in",
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
    assertExists(
      app.buttons["tab.explore"],
      name: "feed-explore-tab",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["header.search"],
      name: "feed-search-button",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["header.notifications"],
      name: "feed-notifications-button",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["tab.post"],
      name: "feed-post-tab",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["tab.saved"],
      name: "feed-saved-tab",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["tab.profile"],
      name: "feed-profile-tab",
      in: app,
      screenshotDir: screenshotDir
    )
    assertValue(
      app.buttons["tab.home"],
      equals: "selected",
      name: "feed-home-tab-selected",
      in: app,
      screenshotDir: screenshotDir
    )
    saveScreenshot(named: "03-feed", to: screenshotDir)

    app.buttons["tab.explore"].tap()
    assertExists(
      app.buttons["map.card.blue-pool"],
      name: "map-card",
      in: app,
      screenshotDir: screenshotDir
    )
    assertValue(
      app.buttons["tab.explore"],
      equals: "selected",
      name: "map-explore-tab-selected",
      in: app,
      screenshotDir: screenshotDir
    )
    saveScreenshot(named: "04-map", to: screenshotDir)

    let mapCard = app.buttons["map.card.blue-pool"]
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
      app.buttons["map.card.blue-pool"],
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
      expectedIdentifier: "welcome.getStarted",
      additionalAssertions: { app, directory in
        self.assertExists(
          app.buttons["welcome.signIn"],
          name: "welcome-sign-in",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.staticTexts["welcome.brandTitle"],
          name: "welcome-brand-title",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.staticTexts["welcome.headline"],
          name: "welcome-headline",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.staticTexts["welcome.subheadline"],
          name: "welcome-subheadline",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.staticTexts["welcome.legal"],
          name: "welcome-legal",
          in: app,
          screenshotDir: directory
        )
        self.assertHittable(
          app.buttons["welcome.getStarted"],
          name: "welcome-get-started",
          in: app,
          screenshotDir: directory
        )
        self.assertHittable(
          app.buttons["welcome.signIn"],
          name: "welcome-sign-in",
          in: app,
          screenshotDir: directory
        )
      }
    )

    try launchAndCapture(
      named: "profile",
      environment: ["UITEST_START_SCREEN": "profile"],
      screenshotDir: screenshotDir,
      expectedIdentifier: "profile.continue",
      additionalAssertions: { app, directory in
        self.assertExists(
          app.buttons["profile.back"],
          name: "profile-back",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.buttons["profile.skip"],
          name: "profile-skip",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.textFields["profile.displayName"],
          name: "profile-display-name",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.textFields["profile.handle"],
          name: "profile-handle",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.textFields["profile.homeCity"],
          name: "profile-home-city",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.textFields["profile.homeRegion"],
          name: "profile-home-region",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.textFields["profile.bio"],
          name: "profile-bio",
          in: app,
          screenshotDir: directory
        )
      }
    )

    try launchAndCapture(
      named: "explore-feed",
      environment: ["UITEST_START_SCREEN": "explore-feed"],
      screenshotDir: screenshotDir,
      expectedIdentifier: "tab.home",
      additionalAssertions: { app, directory in
        self.assertExists(
          app.buttons["tab.explore"],
          name: "feed-explore-tab",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.buttons["header.search"],
          name: "feed-search-button",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.buttons["header.notifications"],
          name: "feed-notifications-button",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.buttons["tab.post"],
          name: "feed-post-tab",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.buttons["tab.saved"],
          name: "feed-saved-tab",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.buttons["tab.profile"],
          name: "feed-profile-tab",
          in: app,
          screenshotDir: directory
        )
        self.assertValue(
          app.buttons["tab.home"],
          equals: "selected",
          name: "feed-home-tab-selected",
          in: app,
          screenshotDir: directory
        )
        self.assertHittable(
          app.buttons["feed.card.\(self.eagleID)"],
          name: "feed-first-card",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.staticTexts["feed.card.title.\(self.eagleID)"],
          name: "feed-first-card-title",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.staticTexts["feed.card.location.\(self.eagleID)"],
          name: "feed-first-card-location",
          in: app,
          screenshotDir: directory
        )
        self.drag(
          in: app.scrollViews["feed.scroll"],
          from: CGVector(dx: 0.5, dy: 0.76),
          to: CGVector(dx: 0.5, dy: 0.24)
        )
      }
    )

    try launchAndCapture(
      named: "explore-map",
      environment: ["UITEST_START_SCREEN": "explore-map"],
      screenshotDir: screenshotDir,
      expectedIdentifier: "map.card.blue-pool",
      additionalAssertions: { app, directory in
        self.assertExists(
          app.buttons.matching(identifier: "map.visibilityBar").firstMatch,
          name: "map-visibility-bar",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.buttons["map.locationButton"],
          name: "map-location-button",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.buttons["List view"],
          name: "map-list-view-button",
          in: app,
          screenshotDir: directory
        )
        self.assertValue(
          app.buttons["tab.explore"],
          equals: "selected",
          name: "map-explore-tab-selected",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.buttons["map.pin.\(self.bluePoolID)"],
          name: "map-selected-pin",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.staticTexts["map.sheet.count"],
          name: "map-sheet-count",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.staticTexts["map.card.title.blue-pool"],
          name: "map-blue-pool-title",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.staticTexts["map.card.title.opal-creek-trail"],
          name: "map-opal-creek-title",
          in: app,
          screenshotDir: directory
        )
        self.assertHittable(
          app.buttons["map.card.blue-pool"],
          name: "map-blue-pool-card",
          in: app,
          screenshotDir: directory
        )
        self.assertNotExists(
          app.staticTexts["Search places..."],
          name: "map-search-removed",
          in: app,
          screenshotDir: directory
        )
      }
    )

    try launchAndCapture(
      named: "detail",
      environment: [
        "UITEST_START_SCREEN": "detail",
        "UITEST_DETAIL_ID": bluePoolID
      ],
      screenshotDir: screenshotDir,
      expectedIdentifier: "detail.back",
      additionalAssertions: { app, directory in
        self.assertExists(
          app.staticTexts["detail.category"],
          name: "detail-category",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.staticTexts["detail.title"],
          name: "detail-title",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.staticTexts["detail.location"],
          name: "detail-location",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.staticTexts.matching(identifier: "detail.ratingSummary").firstMatch,
          name: "detail-rating-summary",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.buttons["detail.startCTA"],
          name: "detail-start-cta",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.staticTexts["detail.aboutBody"],
          name: "detail-about-body",
          in: app,
          screenshotDir: directory
        )
        self.assertExists(
          app.staticTexts["detail.savedCount"],
          name: "detail-saved-count",
          in: app,
          screenshotDir: directory
        )
      }
    )
  }

  func testDetailContentRemainsReadableAboveCTA() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "detail-regressions")
    let app = XCUIApplication()

    app.launchEnvironment["UITEST_START_SCREEN"] = "detail"
    app.launchEnvironment["UITEST_DETAIL_ID"] = bluePoolID
    app.launch()

    assertExists(
      app.buttons["detail.startCTA"],
      name: "detail-start-cta",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["detail.aboutBody"],
      name: "detail-about-body",
      in: app,
      screenshotDir: screenshotDir
    )
    assertFrameAbove(
      app.staticTexts["detail.aboutBody"],
      other: app.buttons["detail.startCTA"],
      name: "detail-about-body-above-cta",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["detail.savedCount"],
      name: "detail-saved-count",
      in: app,
      screenshotDir: screenshotDir
    )
    saveScreenshot(named: "detail-before-scroll", to: screenshotDir)

    app.swipeUp()

    assertExists(
      app.staticTexts["detail.locationSectionTitle"],
      name: "detail-location-section",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["detail.startCTA"],
      name: "detail-start-cta-after-scroll",
      in: app,
      screenshotDir: screenshotDir
    )
    saveScreenshot(named: "detail-after-scroll", to: screenshotDir)
  }

  private func launchAndCapture(
    named name: String,
    environment: [String: String],
    screenshotDir: URL,
    expectedIdentifier: String,
    additionalAssertions: ((XCUIApplication, URL) -> Void)? = nil
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
    additionalAssertions?(app, screenshotDir)
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

  private func assertHittable(
    _ element: XCUIElement,
    name: String,
    in app: XCUIApplication,
    screenshotDir: URL
  ) {
    assertExists(element, name: name, in: app, screenshotDir: screenshotDir)

    guard element.isHittable else {
      print("Element is not hittable for \(name)")
      print(app.debugDescription)
      saveScreenshot(named: "failure-hittable-\(name)", to: screenshotDir)
      XCTFail("Element \(name) is not hittable")
      return
    }
  }

  private func assertValue(
    _ element: XCUIElement,
    equals expectedValue: String,
    name: String,
    in app: XCUIApplication,
    screenshotDir: URL
  ) {
    assertExists(element, name: name, in: app, screenshotDir: screenshotDir)

    let value = element.value as? String
    guard value == expectedValue else {
      print("Unexpected value for \(name): \(String(describing: value))")
      print(app.debugDescription)
      saveScreenshot(named: "failure-value-\(name)", to: screenshotDir)
      XCTFail("Expected value \(expectedValue) for \(name), got \(String(describing: value))")
      return
    }
  }

  private func assertNotExists(
    _ element: XCUIElement,
    name: String,
    in app: XCUIApplication,
    screenshotDir: URL
  ) {
    guard !element.exists else {
      print("Element unexpectedly exists for \(name)")
      print(app.debugDescription)
      saveScreenshot(named: "failure-unexpected-\(name)", to: screenshotDir)
      XCTFail("Element \(name) should not exist")
      return
    }
  }

  private func assertFrameAbove(
    _ element: XCUIElement,
    other otherElement: XCUIElement,
    name: String,
    in app: XCUIApplication,
    screenshotDir: URL
  ) {
    assertExists(element, name: name, in: app, screenshotDir: screenshotDir)
    assertExists(otherElement, name: name, in: app, screenshotDir: screenshotDir)

    let elementMaxY = element.frame.maxY
    let otherMinY = otherElement.frame.minY

    guard elementMaxY <= otherMinY else {
      print("Unexpected frame overlap for \(name): elementMaxY=\(elementMaxY), otherMinY=\(otherMinY)")
      print(app.debugDescription)
      saveScreenshot(named: "failure-frame-\(name)", to: screenshotDir)
      XCTFail("Expected \(name) content to remain above the CTA")
      return
    }
  }

  private func drag(
    in element: XCUIElement,
    from start: CGVector,
    to end: CGVector
  ) {
    let startCoordinate = element.coordinate(withNormalizedOffset: start)
    let endCoordinate = element.coordinate(withNormalizedOffset: end)
    startCoordinate.press(forDuration: 0.05, thenDragTo: endCoordinate)
  }
}
