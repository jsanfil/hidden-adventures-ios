import XCTest

final class ExploreFeedScreenUITests: HiddenAdventuresUITestCase {
  func testExploreFeed_rendersCoreChrome() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "explore-feed-smoke")
    let app = launchApp(startScreen: "explore-feed")

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
    assertHittable(
      app.buttons["feed.card.\(eagleID)"],
      name: "feed-first-card",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["feed.card.title.\(eagleID)"],
      name: "feed-first-card-title",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["feed.card.location.\(eagleID)"],
      name: "feed-first-card-location",
      in: app,
      screenshotDir: screenshotDir
    )

    let categoryChips = app.buttons.matching(
      NSPredicate(format: "identifier BEGINSWITH %@", "explore.category.")
    )
    XCTAssertEqual(categoryChips.count, 8, "Expected exactly 8 category chips in Explore.")
  }

  func testExploreFeed_returningFromDetailPreservesHomeTabChrome() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "explore-feed-detail-return")
    let app = launchApp(startScreen: "explore-feed")

    let feedCard = app.buttons["feed.card.\(eagleID)"]
    assertHittable(
      feedCard,
      name: "feed-detail-entry-card",
      in: app,
      screenshotDir: screenshotDir
    )
    feedCard.tap()

    let detailBackButton = app.buttons["detail.back"]
    assertExists(
      detailBackButton,
      name: "detail-back-after-feed-open",
      in: app,
      screenshotDir: screenshotDir
    )

    let detailScrollView = app.scrollViews.firstMatch
    assertExists(
      detailScrollView,
      name: "detail-scroll-container",
      in: app,
      screenshotDir: screenshotDir
    )
    drag(
      in: detailScrollView,
      from: CGVector(dx: 0.5, dy: 0.78),
      to: CGVector(dx: 0.5, dy: 0.28)
    )

    detailBackButton.tap()

    let homeTab = app.buttons["tab.home"]
    assertExists(
      homeTab,
      name: "feed-home-tab-after-detail-return",
      in: app,
      screenshotDir: screenshotDir
    )
    assertValue(
      homeTab,
      equals: "selected",
      name: "feed-home-tab-selected-after-detail-return",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["feed.card.\(eagleID)"],
      name: "feed-first-card-after-detail-return",
      in: app,
      screenshotDir: screenshotDir
    )
    saveScreenshot(named: "feed-after-detail-return", to: screenshotDir)
  }
}
