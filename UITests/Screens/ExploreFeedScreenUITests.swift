import XCTest

final class ExploreFeedScreenUITests: HiddenAdventuresUITestCase {
  private func anyFeedCard(in app: XCUIApplication) -> XCUIElementQuery {
    app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "feed.card."))
  }

  private func anyFeedCardTitle(in app: XCUIApplication) -> XCUIElementQuery {
    app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "feed.card.title."))
  }

  private func anyFeedCardLocation(in app: XCUIApplication) -> XCUIElementQuery {
    app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "feed.card.location."))
  }

  private func waitForAnyFeedCard(
    in app: XCUIApplication,
    timeout: TimeInterval = 10
  ) -> XCUIElement {
    let firstCard = anyFeedCard(in: app).firstMatch
    XCTAssertTrue(firstCard.waitForExistence(timeout: timeout), "Expected at least one feed card in Explore.")
    return firstCard
  }

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
    assertExists(
      app.scrollViews["feed.scroll"],
      name: "feed-scroll",
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

    app.buttons["header.search"].tap()
    let searchField = app.textFields["feed.searchField"]
    assertExists(searchField, name: "feed-search-field-before-detail", in: app, screenshotDir: screenshotDir)
    searchField.tap()
    searchField.typeText("Port")
    assertExists(
      app.buttons["feed.searchSuggestion.portland-oregon"],
      name: "feed-search-suggestion-before-detail",
      in: app,
      screenshotDir: screenshotDir
    )
    app.buttons["feed.searchSuggestion.portland-oregon"].tap()

    let feedCard = waitForAnyFeedCard(in: app)
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
    assertExists(feedCard, name: "feed-first-card-after-detail-return", in: app, screenshotDir: screenshotDir)
    saveScreenshot(named: "feed-after-detail-return", to: screenshotDir)
  }

  func testExploreFeed_placeSearchSuggestionsSyncWithMap() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "explore-feed-search")
    let app = launchApp(startScreen: "explore-feed")

    let searchButton = app.buttons["header.search"]
    assertHittable(
      searchButton,
      name: "feed-search-expand-button",
      in: app,
      screenshotDir: screenshotDir
    )
    searchButton.tap()

    let searchField = app.textFields["feed.searchField"]
    assertExists(
      searchField,
      name: "feed-search-field",
      in: app,
      screenshotDir: screenshotDir
    )
    searchField.tap()
    searchField.typeText("Port")

    assertExists(
      app.otherElements["feed.searchSuggestions"],
      name: "feed-search-suggestions",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["feed.searchSuggestion.portland-oregon"],
      name: "feed-search-suggestion-portland",
      in: app,
      screenshotDir: screenshotDir
    )

    app.buttons["feed.searchSuggestion.portland-oregon"].tap()

    assertNotExists(
      app.otherElements["feed.searchSuggestions"],
      name: "feed-search-suggestions-dismissed",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(waitForAnyFeedCard(in: app), name: "feed-card-still-visible-after-search", in: app, screenshotDir: screenshotDir)

    app.buttons["tab.explore"].tap()

    assertExists(
      app.textFields["map.searchField"],
      name: "map-search-field-after-feed-selection",
      in: app,
      screenshotDir: screenshotDir
    )
    assertValue(
      app.textFields["map.searchField"],
      equals: "Portland, Oregon",
      name: "map-search-field-synced-value",
      in: app,
      screenshotDir: screenshotDir
    )
  }
}
