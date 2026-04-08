import XCTest

final class ExploreMapScreenUITests: HiddenAdventuresUITestCase {
  func testExploreMap_rendersCoreChrome() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "explore-map-smoke")
    let app = launchApp(startScreen: "explore-map")

    assertExists(
      app.buttons.matching(identifier: "map.visibilityBar").firstMatch,
      name: "map-visibility-bar",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["map.locationButton"],
      name: "map-location-button",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["List view"],
      name: "map-list-view-button",
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
      app.buttons["map.pin.\(bluePoolID)"],
      name: "map-selected-pin",
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
      app.buttons["map.card.blue-pool"],
      name: "map-blue-pool-card",
      in: app,
      screenshotDir: screenshotDir
    )
    assertNotExists(
      app.staticTexts["Search places..."],
      name: "map-search-removed",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testExploreMap_selectedPinVisible() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "explore-map-pin-smoke")
    let app = launchApp(startScreen: "explore-map")

    assertExists(
      app.buttons["map.pin.\(bluePoolID)"],
      name: "map-selected-pin",
      in: app,
      screenshotDir: screenshotDir
    )
  }
}
