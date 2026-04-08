import XCTest

final class DetailScreenUITests: HiddenAdventuresUITestCase {
  func testDetail_rendersCoreChrome() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "detail-smoke")
    let app = launchApp(
      startScreen: "detail",
      extraEnv: ["UITEST_DETAIL_ID": bluePoolID]
    )

    assertExists(
      app.buttons["detail.back"],
      name: "detail-back",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["detail.share"],
      name: "detail-share",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["detail.favorite"],
      name: "detail-favorite",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["detail.category"],
      name: "detail-category",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["detail.title"],
      name: "detail-title",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["detail.location"],
      name: "detail-location",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts.matching(identifier: "detail.ratingSummary").firstMatch,
      name: "detail-rating-summary",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts.matching(identifier: "detail.comments").firstMatch,
      name: "detail-comments",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["detail.description"],
      name: "detail-description",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["detail.author"],
      name: "detail-author",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["detail.locationSectionTitle"],
      name: "detail-location-section",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["detail.follow"],
      name: "detail-follow",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.textFields["detail.composer"],
      name: "detail-composer",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["detail.composer"],
      name: "detail-send",
      in: app,
      screenshotDir: screenshotDir
    )
  }
}
