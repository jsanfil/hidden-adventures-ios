import XCTest

final class CreateLocationSheetUITests: HiddenAdventuresUITestCase {
  func testCreateLocationOptions_rendersCoreChrome() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "create-location-options-smoke")
    let app = launchApp(startScreen: "create-location-options")

    assertExists(
      app.buttons["create.locationSheet.searchPlaces"],
      name: "create-search-places",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["create.locationSheet.title"],
      name: "create-location-sheet-title",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["create.locationSheet.currentLocation"],
      name: "create-current-location",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["create.locationSheet.dropPin"],
      name: "create-drop-pin",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testCreateLocationSearchEmpty_rendersCoreChrome() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "create-location-search-empty-smoke")
    let app = launchApp(startScreen: "create-location-search-empty")

    assertExists(
      app.buttons["create.locationSheet.back"],
      name: "create-location-back",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.textFields["create.locationSheet.searchField"],
      name: "create-search-field",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["create.locationSheet.searchEmpty"],
      name: "create-search-empty",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testCreateLocationSearchResults_rendersCoreChrome() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "create-location-search-results-smoke")
    let app = launchApp(startScreen: "create-location-search-results")

    assertExists(
      app.buttons["create.locationSheet.back"],
      name: "create-location-back",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.textFields["create.locationSheet.searchField"],
      name: "create-search-field-results",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["create.locationSheet.result.yosemite"],
      name: "create-search-result-yosemite",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["create.locationSheet.result.crater-lake"],
      name: "create-search-result-crater",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testCreateLocationPin_rendersCoreChrome() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "create-location-pin-smoke")
    let app = launchApp(startScreen: "create-location-pin")

    assertExists(
      app.buttons["create.locationSheet.confirmPin"],
      name: "create-confirm-pin",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.images["create.locationSheet.pinMap"],
      name: "create-pin-map",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["create.locationSheet.pinSummary"],
      name: "create-pin-summary",
      in: app,
      screenshotDir: screenshotDir
    )
  }
}
