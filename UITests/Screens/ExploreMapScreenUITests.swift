import XCTest

final class ExploreMapScreenUITests: HiddenAdventuresUITestCase {
  func testExploreMap_rendersCoreChrome() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "explore-map-smoke")
    let app = launchApp(startScreen: "explore-map")

    assertExists(
      app.textFields["map.searchField"],
      name: "map-search-field",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["map.filterButton"],
      name: "map-filter-button",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["map.recenterButton"],
      name: "map-recenter-button",
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
    assertExists(
      app.staticTexts["map.sheet.count"],
      name: "map-sheet-count",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["map.card.title.blue-pool"],
      name: "map-blue-pool-title",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["map.card.title.opal-creek-trail"],
      name: "map-opal-creek-title",
      in: app,
      screenshotDir: screenshotDir
    )
    assertHittable(
      app.buttons["map.card.\(bluePoolID)"],
      name: "map-blue-pool-card",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["map.sheet.modeButton"],
      name: "map-sheet-mode-button",
      in: app,
      screenshotDir: screenshotDir
    )
    assertNotExists(
      app.staticTexts["0.0"],
      name: "map-peek-rating-hidden",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testExploreMap_filterPopoverVisible() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "explore-map-filter")
    let app = launchApp(startScreen: "explore-map")

    app.buttons["map.filterButton"].tap()

    assertExists(
      app.buttons["map.filter.option.all"],
      name: "map-filter-all-option",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["map.filter.option.public"],
      name: "map-filter-public-option",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["map.filter.option.sidekicks"],
      name: "map-filter-sidekicks-option",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["map.filter.option.private"],
      name: "map-filter-private-option",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testExploreMap_selectedPinShowsPreview() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "explore-map-pin-smoke")
    let app = launchApp(startScreen: "explore-map")

    app.buttons["map.card.\(bluePoolID)"].tap()

    assertExists(
      app.otherElements["map.preview"],
      name: "map-preview-card",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["map.preview.close"],
      name: "map-preview-close",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testExploreMap_expandedSheetShowsListRows() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "explore-map-expanded")
    let app = launchApp(startScreen: "explore-map")

    app.buttons["map.sheet.modeButton"].tap()

    assertExists(
      app.buttons["map.listrow.\(bluePoolID)"],
      name: "map-blue-pool-list-row",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["map.listrow.\(eagleID)"],
      name: "map-eagle-list-row",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["2.4 mi"],
      name: "map-expanded-distance-visible",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["4.8"],
      name: "map-expanded-rating-visible",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testExploreMap_placeSearchSuggestionsRecenterFlow() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "explore-map-search")
    let app = launchApp(startScreen: "explore-map")

    let searchField = app.textFields["map.searchField"]
    searchField.tap()
    searchField.typeText("Port")

    assertExists(
      app.otherElements["map.searchSuggestions"],
      name: "map-search-suggestions",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["map.searchSuggestion.portland-oregon"],
      name: "map-search-suggestion-portland",
      in: app,
      screenshotDir: screenshotDir
    )

    app.buttons["map.searchSuggestion.portland-oregon"].tap()

    assertNotExists(
      app.otherElements["map.searchSuggestions"],
      name: "map-search-suggestions-dismissed",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["map.recenterButton"],
      name: "map-recenter-still-visible",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testExploreMap_placeSelectionSyncsBackToFeedAndClearsSharedScope() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "explore-map-feed-sync")
    let app = launchApp(startScreen: "explore-map")

    let searchField = app.textFields["map.searchField"]
    searchField.tap()
    searchField.typeText("Port")

    assertExists(
      app.buttons["map.searchSuggestion.portland-oregon"],
      name: "map-search-suggestion-portland-sync",
      in: app,
      screenshotDir: screenshotDir
    )
    app.buttons["map.searchSuggestion.portland-oregon"].tap()

    app.buttons["tab.home"].tap()

    let searchButton = app.buttons["header.search"]
    assertExists(
      searchButton,
      name: "feed-search-button-after-map-selection",
      in: app,
      screenshotDir: screenshotDir
    )
    searchButton.tap()

    let feedSearchField = app.textFields["feed.searchField"]
    assertValue(
      feedSearchField,
      equals: "Portland, Oregon",
      name: "feed-search-field-synced-value",
      in: app,
      screenshotDir: screenshotDir
    )

    app.buttons["feed.searchClear"].tap()

    assertNotExists(
      app.textFields["feed.searchField"],
      name: "feed-search-collapsed-after-clear",
      in: app,
      screenshotDir: screenshotDir
    )

    app.buttons["tab.explore"].tap()
    assertValue(
      app.textFields["map.searchField"],
      equals: "Search for a place...",
      name: "map-search-cleared-after-feed-clear",
      in: app,
      screenshotDir: screenshotDir
    )
  }
}
