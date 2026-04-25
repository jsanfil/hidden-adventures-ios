import XCTest

final class DiscoverScreenUITests: HiddenAdventuresUITestCase {
  func testDiscoverLiveAutomationRendersServerHomeAndSearchResults() throws {
    let token = ProcessInfo.processInfo.environment["HA_DISCOVER_E2E_AUTH_TOKEN"]
      ?? ProcessInfo.processInfo.environment["HA_TEST_AUTH_TOKEN"]
      ?? Self.readLiveAutomationTokenFromTempFile()
    guard let token, token.isEmpty == false else {
      throw XCTSkip("Provide HA_DISCOVER_E2E_AUTH_TOKEN, HA_TEST_AUTH_TOKEN, or /tmp/hidden_adventures_discover_e2e_token to run live Discover automation.")
    }

    let screenshotDir = try preparedScreenshotDirectory(named: "discover-live-automation")
    let app = launchApp(
      startScreen: "discover",
      extraEnv: [
        "HA_RUNTIME_MODE": "live",
        "HA_SERVER_MODE": "local_automation",
        "HA_API_BASE_URL": ProcessInfo.processInfo.environment["HA_API_BASE_URL"] ?? "http://127.0.0.1:3000/api",
        "HA_TEST_AUTH_TOKEN": token
      ]
    )

    assertExists(
      app.staticTexts["discover.section.exploreAdventurers"],
      name: "discover-live-explore-adventurers-section",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["discover.section.popularAdventures"],
      name: "discover-live-popular-adventures-section",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["Fixture Author"],
      name: "discover-live-fixture-author",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["Fixture Falls"],
      name: "discover-live-fixture-falls",
      in: app,
      screenshotDir: screenshotDir
    )

    app.textFields["discover.searchField"].tap()
    app.textFields["discover.searchField"].typeText("Fixture")

    assertExists(
      app.staticTexts["discover.search.peopleSection"],
      name: "discover-live-search-people-section",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["discover.search.adventuresSection"],
      name: "discover-live-search-adventures-section",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["Fixture Author"],
      name: "discover-live-search-fixture-author",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["Fixture Falls"],
      name: "discover-live-search-fixture-falls",
      in: app,
      screenshotDir: screenshotDir
    )

    saveScreenshot(named: "discover-live-automation", to: screenshotDir)
  }

  private static func readLiveAutomationTokenFromTempFile() -> String? {
    let tokenURL = URL(fileURLWithPath: "/tmp/hidden_adventures_discover_e2e_token")
    guard let token = try? String(contentsOf: tokenURL, encoding: .utf8) else {
      return nil
    }

    let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedToken.isEmpty ? nil : trimmedToken
  }

  func testDiscoverHomeRendersFixtureModulesAndSearchResults() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "discover-home")
    let app = launchApp(startScreen: "discover")

    assertExists(
      app.staticTexts["discover.title"],
      name: "discover-title",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.textFields["discover.searchField"],
      name: "discover-search-field",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["discover.adventurerCard.adventurer-maya-reyes"],
      name: "discover-maya-card",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["discover.adventureCard.adventure-eagle-creek"],
      name: "discover-eagle-card",
      in: app,
      screenshotDir: screenshotDir
    )

    app.textFields["discover.searchField"].tap()
    app.textFields["discover.searchField"].typeText("e")

    assertExists(
      app.staticTexts["discover.search.peopleSection"],
      name: "discover-search-people-section",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["discover.search.adventuresSection"],
      name: "discover-search-adventures-section",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["discover.personRow.adventurer-maya-reyes"],
      name: "discover-search-maya-view",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["discover.adventureRow.adventure-eagle-creek"],
      name: "discover-search-eagle-row",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["discover.searchClear"],
      name: "discover-search-clear",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testDiscoverEmptyFixtureRendersNoResultsState() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "discover-empty")
    let app = launchApp(
      startScreen: "discover",
      extraEnv: [
        "DISCOVER_FIXTURE_VARIANT": "empty"
      ]
    )

    app.textFields["discover.searchField"].tap()
    app.textFields["discover.searchField"].typeText("zzzz")

    assertExists(
      app.staticTexts["discover.search.emptyState"].firstMatch,
      name: "discover-empty-state",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testDiscoverAdventurerCarouselCardOpensExistingProfileView() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "discover-carousel-profile-navigation")
    let app = launchApp(startScreen: "discover")

    let mayaCard = app.buttons["discover.adventurerCard.adventurer-maya-reyes"]
    assertHittable(
      mayaCard,
      name: "discover-maya-card-navigation",
      in: app,
      screenshotDir: screenshotDir
    )
    mayaCard.tap()

    assertExists(
      app.buttons["profile.back"],
      name: "discover-profile-back",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["profile.handle.readonly"],
      name: "discover-profile-handle",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["@mayaexplores"],
      name: "discover-profile-selected-handle",
      in: app,
      screenshotDir: screenshotDir
    )
    assertNotExists(
      app.buttons["profile.sidekicksCard"],
      name: "discover-profile-hides-viewer-only-sidekicks-card",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["profile.sharedAdventuresHeading"],
      name: "discover-profile-shared-adventures-heading",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["feed.card.AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"],
      name: "discover-profile-public-adventure",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testDiscoverPeopleSearchRowOpensExistingProfileView() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "discover-search-profile-navigation")
    let app = launchApp(startScreen: "discover")

    app.textFields["discover.searchField"].tap()
    app.textFields["discover.searchField"].typeText("theo")

    let theoRow = app.buttons["discover.personRow.adventurer-theo-nakamura"]
    assertHittable(
      theoRow,
      name: "discover-theo-search-row",
      in: app,
      screenshotDir: screenshotDir
    )
    theoRow.tap()

    assertExists(
      app.buttons["profile.back"],
      name: "discover-search-profile-back",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["@theo.outdoors"],
      name: "discover-search-profile-selected-handle",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["profile.sharedAdventuresHeading"],
      name: "discover-search-profile-shared-adventures-heading",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["feed.card.BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"],
      name: "discover-search-profile-public-adventure",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testDiscoverPopularAdventureCardOpensExistingDetailView() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "discover-carousel-detail-navigation")
    let app = launchApp(startScreen: "discover")

    let eagleCard = app.buttons["discover.adventureCard.adventure-eagle-creek"]
    assertHittable(
      eagleCard,
      name: "discover-eagle-card-navigation",
      in: app,
      screenshotDir: screenshotDir
    )
    eagleCard.tap()

    assertExists(
      app.buttons["detail.back"],
      name: "discover-detail-back",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["detail.title"],
      name: "discover-detail-title",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["Eagle Creek Trail to Tunnel Falls"],
      name: "discover-detail-expected-title",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testDiscoverAdventureSearchRowOpensExistingDetailView() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "discover-search-detail-navigation")
    let app = launchApp(startScreen: "discover")

    app.textFields["discover.searchField"].tap()
    app.textFields["discover.searchField"].typeText("Blue")

    let bluePoolRow = app.buttons["discover.adventureRow.adventure-blue-pool"]
    assertHittable(
      bluePoolRow,
      name: "discover-blue-pool-search-row",
      in: app,
      screenshotDir: screenshotDir
    )
    bluePoolRow.tap()

    assertExists(
      app.buttons["detail.back"],
      name: "discover-search-detail-back",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["detail.title"],
      name: "discover-search-detail-title",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["Blue Pool at Tamolitch Falls"],
      name: "discover-search-detail-expected-title",
      in: app,
      screenshotDir: screenshotDir
    )
  }
}
