import XCTest

final class WalkthroughFlowUITests: HiddenAdventuresUITestCase {
  func testSlice1WalkthroughCapturesScreenshots() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "walkthrough")
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

    app.buttons["tab.post"].tap()
    assertExists(
      app.buttons["create.next"],
      name: "create-next",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.images["create.photoPreview"],
      name: "create-photo-preview",
      in: app,
      screenshotDir: screenshotDir
    )
    assertHittable(
      app.buttons["create.photoGrid.hero-mountain"],
      name: "create-photo-grid",
      in: app,
      screenshotDir: screenshotDir
    )
    saveScreenshot(named: "04-create-photos", to: screenshotDir)

    app.buttons["create.close"].tap()
    assertExists(
      app.buttons["tab.explore"],
      name: "feed-return-after-create",
      in: app,
      screenshotDir: screenshotDir
    )

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
    saveScreenshot(named: "05-map", to: screenshotDir)

    let mapCard = app.buttons["map.card.blue-pool"]
    assertExists(mapCard, name: "map-card-tap", in: app, screenshotDir: screenshotDir)
    mapCard.tap()

    assertExists(
      app.buttons["detail.back"],
      name: "detail-back",
      in: app,
      screenshotDir: screenshotDir
    )
    saveScreenshot(named: "06-detail", to: screenshotDir)

    app.buttons["detail.back"].tap()
    assertExists(
      app.buttons["map.card.blue-pool"],
      name: "map-return",
      in: app,
      screenshotDir: screenshotDir
    )
    saveScreenshot(named: "07-map-return", to: screenshotDir)
  }
}
