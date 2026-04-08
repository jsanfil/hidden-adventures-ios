import XCTest

final class CreatePhotosScreenUITests: HiddenAdventuresUITestCase {
  func testCreatePhotos_rendersCoreChrome() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "create-photos-smoke")
    let app = launchApp(startScreen: "create-photos")

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
    assertExists(
      app.staticTexts["create.header.title"],
      name: "create-header-title",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["create.photoCount"],
      name: "create-photo-count",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["create.photoGrid.add"],
      name: "create-add-photo",
      in: app,
      screenshotDir: screenshotDir
    )
    assertHittable(
      app.buttons["create.photoGrid.hero-mountain"],
      name: "create-first-photo",
      in: app,
      screenshotDir: screenshotDir
    )
  }
}
