import XCTest

class HiddenAdventuresUITestCase: XCTestCase {
  let eagleID = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
  let bluePoolID = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func makeApp(
    startScreen: String? = nil,
    extraEnv: [String: String] = [:]
  ) -> XCUIApplication {
    let app = XCUIApplication()

    if let startScreen {
      app.launchEnvironment["UITEST_START_SCREEN"] = startScreen
    }
    extraEnv.forEach { key, value in
      app.launchEnvironment[key] = value
    }

    return app
  }

  func launchApp(
    startScreen: String? = nil,
    extraEnv: [String: String] = [:]
  ) -> XCUIApplication {
    let app = makeApp(startScreen: startScreen, extraEnv: extraEnv)
    app.launch()
    return app
  }

  func preparedScreenshotDirectory(named name: String) throws -> URL {
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

  func captureScreen(
    named name: String,
    startScreen: String,
    extraEnv: [String: String] = [:],
    expectedIdentifier: String,
    additionalAssertions: ((XCUIApplication, URL) -> Void)? = nil
  ) throws {
    let screenshotDir = try preparedScreenshotDirectory(named: name)
    let app = makeApp(startScreen: startScreen, extraEnv: extraEnv)
    defer { app.terminate() }

    app.launch()
    assertExists(
      app.buttons[expectedIdentifier],
      name: name,
      in: app,
      screenshotDir: screenshotDir
    )
    additionalAssertions?(app, screenshotDir)
    saveScreenshot(named: name, to: screenshotDir)
  }

  func saveScreenshot(named name: String, to directory: URL) {
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

  func assertExists(
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

  func assertHittable(
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

  func assertValue(
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

  func assertNotExists(
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

  func assertFrameAbove(
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

  func drag(
    in element: XCUIElement,
    from start: CGVector,
    to end: CGVector
  ) {
    let startCoordinate = element.coordinate(withNormalizedOffset: start)
    let endCoordinate = element.coordinate(withNormalizedOffset: end)
    startCoordinate.press(forDuration: 0.05, thenDragTo: endCoordinate)
  }
}
