import XCTest

final class CreateDetailsScreenUITests: HiddenAdventuresUITestCase {
  func testCreateDetailsEmpty_rendersCoreChrome() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "create-details-empty-smoke")
    let app = launchApp(startScreen: "create-details-empty")

    assertExists(
      app.buttons["create.post"],
      name: "create-post",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.textFields["create.title"],
      name: "create-title",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.textFields["create.description"],
      name: "create-description",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["create.location.coordinatesButton"],
      name: "create-location-button",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.textFields["create.location.label"],
      name: "create-location-label",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["create.category.trails"],
      name: "create-category-trails",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["create.visibility.public"],
      name: "create-visibility-public",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["create.visibility.sidekicks"],
      name: "create-visibility-sidekicks",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testCreateDetailsLocation_rendersCoreChrome() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "create-details-location-smoke")
    let app = launchApp(startScreen: "create-details-location")

    assertExists(
      app.buttons["create.location.clearCoordinates"],
      name: "create-clear-coordinates",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["create.location.clearLabel"],
      name: "create-clear-label",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["create.location.helper"],
      name: "create-location-helper",
      in: app,
      screenshotDir: screenshotDir
    )
  }
}
