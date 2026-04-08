import XCTest

final class DetailLayoutRegressionUITests: HiddenAdventuresUITestCase {
  func testDetailContentRemainsReadableAboveCTA() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "detail-regressions")
    let app = makeApp(
      startScreen: "detail",
      extraEnv: ["UITEST_DETAIL_ID": bluePoolID]
    )

    app.launch()

    assertExists(
      app.textFields["detail.composer"],
      name: "detail-composer",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["detail.description"],
      name: "detail-description",
      in: app,
      screenshotDir: screenshotDir
    )
    assertFrameAbove(
      app.staticTexts["detail.description"],
      other: app.textFields["detail.composer"],
      name: "detail-description-above-composer",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts.matching(identifier: "detail.comments").firstMatch,
      name: "detail-comments",
      in: app,
      screenshotDir: screenshotDir
    )
    saveScreenshot(named: "detail-before-scroll", to: screenshotDir)

    app.swipeUp()

    assertExists(
      app.staticTexts["detail.locationSectionTitle"],
      name: "detail-location-section",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.textFields["detail.composer"],
      name: "detail-composer-after-scroll",
      in: app,
      screenshotDir: screenshotDir
    )
    saveScreenshot(named: "detail-after-scroll", to: screenshotDir)
  }
}
