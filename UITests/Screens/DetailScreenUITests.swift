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
      app.buttons["detail.author"],
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
      app.buttons["detail.send"],
      name: "detail-send",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testDetail_favoriteButtonReflectsAndTogglesFavoriteState() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "detail-favorite-toggle")
    let app = launchApp(
      startScreen: "detail",
      extraEnv: ["UITEST_DETAIL_ID": bluePoolID]
    )

    let favoriteButton = app.buttons["detail.favorite"]
    assertExists(
      favoriteButton,
      name: "detail-favorite-button",
      in: app,
      screenshotDir: screenshotDir
    )
    assertValue(
      favoriteButton,
      equals: "not favorited",
      name: "detail-favorite-button-initial-state",
      in: app,
      screenshotDir: screenshotDir
    )

    favoriteButton.tap()

    assertValue(
      favoriteButton,
      equals: "favorited",
      name: "detail-favorite-button-toggled-state",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testDetail_noCommentsShowsEmptyState() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "detail-no-comments")
    let app = launchApp(
      startScreen: "detail",
      extraEnv: [
        "UITEST_DETAIL_ID": bluePoolID,
        "UITEST_DETAIL_VARIANT": "no-comments"
      ]
    )

    assertExists(
      app.staticTexts["No comments yet. Be the first!"],
      name: "detail-comments-empty",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testDetail_submitCommentClearsDraftAndShowsNewComment() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "detail-submit-comment")
    let app = launchApp(
      startScreen: "detail",
      extraEnv: ["UITEST_DETAIL_ID": bluePoolID]
    )

    let composer = app.textFields["detail.composer"]
    let sendButton = app.buttons["detail.send"]

    assertExists(composer, name: "detail-composer", in: app, screenshotDir: screenshotDir)
    XCTAssertFalse(sendButton.isEnabled, "Send button should start disabled.")

    composer.tap()
    composer.typeText("Fresh fixture comment")

    XCTAssertTrue(sendButton.isEnabled, "Send button should enable after entering text.")
    sendButton.tap()

    assertExists(
      app.staticTexts["Fresh fixture comment"],
      name: "detail-new-comment",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testDetail_scrollLoadsMoreComments() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "detail-scroll-comments")
    let app = launchApp(
      startScreen: "detail",
      extraEnv: ["UITEST_DETAIL_ID": bluePoolID]
    )

    let commentsSection = app.scrollViews.firstMatch
    assertExists(
      commentsSection,
      name: "detail-scroll-view",
      in: app,
      screenshotDir: screenshotDir
    )

    let pagedComment = app.staticTexts["Fixture 21"]
    for _ in 0..<8 where pagedComment.exists == false {
      commentsSection.swipeUp()
    }

    assertExists(
      pagedComment,
      name: "detail-paged-comment",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testDetail_ratingCanBeCreatedUpdatedAndCleared() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "detail-rating-flow")
    let app = launchApp(
      startScreen: "detail",
      extraEnv: ["UITEST_DETAIL_ID": bluePoolID]
    )

    let ratingStars = app.otherElements.matching(identifier: "detail.ratingStars")
    let fourStarButton = ratingStars.element(boundBy: 3)
    let twoStarButton = ratingStars.element(boundBy: 1)
    let clearButton = app.buttons["detail.ratingClear"]
    assertExists(fourStarButton, name: "detail-rating-four", in: app, screenshotDir: screenshotDir)
    fourStarButton.tap()

    assertValue(
      fourStarButton,
      equals: "selected",
      name: "detail-rating-four-selected",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(clearButton, name: "detail-rating-clear-visible", in: app, screenshotDir: screenshotDir)

    twoStarButton.tap()

    assertValue(
      twoStarButton,
      equals: "selected",
      name: "detail-rating-two-selected",
      in: app,
      screenshotDir: screenshotDir
    )

    clearButton.tap()

    assertValue(
      twoStarButton,
      equals: "not selected",
      name: "detail-rating-cleared",
      in: app,
      screenshotDir: screenshotDir
    )
  }
}
