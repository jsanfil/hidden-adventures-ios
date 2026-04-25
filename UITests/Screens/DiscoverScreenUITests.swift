import XCTest

final class DiscoverScreenUITests: HiddenAdventuresUITestCase {
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
