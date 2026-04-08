import XCTest

final class WelcomeScreenUITests: HiddenAdventuresUITestCase {
  func testWelcome_rendersCoreChrome() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "welcome-smoke")
    let app = launchApp(startScreen: "welcome")

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
      app.staticTexts["welcome.subheadline"],
      name: "welcome-subheadline",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["welcome.legal"],
      name: "welcome-legal",
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
  }
}
