import XCTest

final class ProfileScreenUITests: HiddenAdventuresUITestCase {
  func testProfile_rendersCoreChrome() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "profile-smoke")
    let app = launchApp(startScreen: "profile")

    assertExists(
      app.buttons["profile.back"],
      name: "profile-back",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["profile.skip"],
      name: "profile-skip",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.textFields["profile.displayName"],
      name: "profile-display-name",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.textFields["profile.handle"],
      name: "profile-handle",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.textFields["profile.homeCity"],
      name: "profile-home-city",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.textFields["profile.homeRegion"],
      name: "profile-home-region",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.textFields["profile.bio"],
      name: "profile-bio",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["profile.continue"],
      name: "profile-continue",
      in: app,
      screenshotDir: screenshotDir
    )
  }
}
