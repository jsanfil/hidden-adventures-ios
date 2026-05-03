import XCTest

final class ProfileScreenUITests: HiddenAdventuresUITestCase {
  func testInviteFriends_andShareAdventure_smoke() throws {
    let profileApp = launchApp(startScreen: "explore-profile")

    XCTAssertTrue(profileApp.buttons["profile.inviteFriends"].waitForExistence(timeout: 2))
    XCTAssertTrue(profileApp.buttons["profile.inviteFriends"].isEnabled)
    profileApp.terminate()

    let detailApp = launchApp(
      startScreen: "detail",
      extraEnv: ["UITEST_DETAIL_ID": eagleID]
    )

    XCTAssertTrue(detailApp.buttons["detail.share"].waitForExistence(timeout: 2))
  }

  func testProfile_inviteFriendsButtonIsAvailable() throws {
    let app = launchApp(startScreen: "explore-profile")

    XCTAssertTrue(app.buttons["profile.inviteFriends"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.buttons["profile.inviteFriends"].isEnabled)
  }

  func testProfile_rendersSidekicksEntryPoint() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "profile-sidekicks-smoke")
    let app = launchApp(startScreen: "explore-profile")

    assertExists(
      app.scrollViews["profile.scroll"],
      name: "profile-scroll",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["profile.logout"],
      name: "profile-logout",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["profile.stat.adventures"].firstMatch,
      name: "profile-stat-adventures",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["profile.stat.likes"].firstMatch,
      name: "profile-stat-likes",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["profile.stat.views"].firstMatch,
      name: "profile-stat-views",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["profile.sidekicksCard"],
      name: "profile-sidekicks-card",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["profile.sharedAdventuresHeading"],
      name: "profile-shared-adventures-heading",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testProfile_viewerFavoritesShowsPopulatedCollection() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "profile-favorites-populated")
    let app = launchApp(
      startScreen: "explore-profile",
      extraEnv: ["UITEST_PROFILE_FAVORITES": "populated"]
    )

    assertExists(
      app.buttons["profile.segment.favorites"],
      name: "profile-favorites-segment",
      in: app,
      screenshotDir: screenshotDir
    )
    app.buttons["profile.segment.favorites"].tap()

    assertExists(
      app.staticTexts["profile.favoriteAdventuresHeading"],
      name: "profile-favorite-adventures-heading",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["feed.card.\(bluePoolID)"],
      name: "profile-favorite-adventure-card",
      in: app,
      screenshotDir: screenshotDir
    )
    assertNotExists(
      app.staticTexts["profile.favorites.empty"],
      name: "profile-favorites-empty-hidden",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testProfile_viewerFavoritesShowsEmptyState() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "profile-favorites-empty")
    let app = launchApp(
      startScreen: "explore-profile",
      extraEnv: ["UITEST_PROFILE_FAVORITES": "empty"]
    )

    assertExists(
      app.buttons["profile.segment.favorites"],
      name: "profile-favorites-segment-empty",
      in: app,
      screenshotDir: screenshotDir
    )
    app.buttons["profile.segment.favorites"].tap()

    assertExists(
      app.staticTexts["profile.favorites.empty"],
      name: "profile-favorites-empty-state",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testProfile_otherProfileDoesNotShowFavoritesSegment() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "profile-favorites-hidden-other-user")
    let app = launchApp(startScreen: "explore-profile")

    app.buttons["profile.sidekicksCard"].tap()
    let rowButton = app.buttons["sidekicks.row.sarahc"]
    assertHittable(
      rowButton,
      name: "sidekicks-row-open-sarah-for-favorites-hidden",
      in: app,
      screenshotDir: screenshotDir
    )
    rowButton.tap()

    assertExists(
      app.buttons["profile.back"],
      name: "other-profile-loaded",
      in: app,
      screenshotDir: screenshotDir
    )
    assertNotExists(
      app.buttons["profile.segment.favorites"],
      name: "other-profile-favorites-segment-hidden",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testSidekicks_supportsTabsSearchAndActions() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "profile-sidekicks-interactions")
    let app = launchApp(startScreen: "explore-profile")

    let sidekicksCard = app.buttons["profile.sidekicksCard"]
    assertHittable(
      sidekicksCard,
      name: "profile-sidekicks-card",
      in: app,
      screenshotDir: screenshotDir
    )
    sidekicksCard.tap()

    assertExists(
      app.buttons["sidekicks.back"],
      name: "sidekicks-back",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["Find Users"],
      name: "sidekicks-find-users-tab",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.textFields["sidekicks.searchField"],
      name: "sidekicks-search-field",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["sidekicks.row.sarahc"],
      name: "sidekicks-row-sarah",
      in: app,
      screenshotDir: screenshotDir
    )
    assertHittable(
      app.buttons["sidekicks.row.sarahc"],
      name: "sidekicks-row-open-sarah",
      in: app,
      screenshotDir: screenshotDir
    )

    let searchField = app.textFields["sidekicks.searchField"]
    searchField.tap()
    searchField.typeText("mi")

    assertExists(
      app.buttons["sidekicks.row.mikerod"],
      name: "sidekicks-row-mike",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["sidekicks.row.jamiel"],
      name: "sidekicks-row-jamie",
      in: app,
      screenshotDir: screenshotDir
    )
    assertNotExists(
      app.buttons["sidekicks.row.sarahc"],
      name: "sidekicks-row-sarah-filtered-out",
      in: app,
      screenshotDir: screenshotDir
    )

    app.buttons["Find Users"].tap()
    searchField.tap()
    searchField.typeText("riley")
    assertExists(
      app.buttons["sidekicks.add.rileyj"],
      name: "sidekicks-add-riley",
      in: app,
      screenshotDir: screenshotDir
    )
    app.buttons["sidekicks.add.rileyj"].tap()
    assertExists(
      app.buttons["sidekicks.remove.rileyj"],
      name: "sidekicks-remove-riley",
      in: app,
      screenshotDir: screenshotDir
    )

    app.buttons["My Sidekicks"].tap()
    assertExists(
      app.buttons["sidekicks.remove.mikerod"],
      name: "sidekicks-remove-mike",
      in: app,
      screenshotDir: screenshotDir
    )
    app.buttons["sidekicks.remove.mikerod"].tap()
    assertExists(
      app.buttons["sidekicks.confirmRemove.mikerod"],
      name: "sidekicks-confirm-remove-mike",
      in: app,
      screenshotDir: screenshotDir
    )
    app.buttons["sidekicks.cancelRemove.mikerod"].tap()
    assertExists(
      app.buttons["sidekicks.remove.mikerod"],
      name: "sidekicks-remove-mike-restored",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testSidekicks_rowMainContentOpensProfileAndHidesSelfOnlyActions() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "sidekicks-row-profile-navigation")
    let app = launchApp(startScreen: "explore-profile")

    app.buttons["profile.sidekicksCard"].tap()

    let rowButton = app.buttons["sidekicks.row.sarahc"]
    assertHittable(
      rowButton,
      name: "sidekicks-row-open-sarah",
      in: app,
      screenshotDir: screenshotDir
    )
    rowButton.tap()

    assertExists(
      app.buttons["profile.back"],
      name: "other-profile-back",
      in: app,
      screenshotDir: screenshotDir
    )
    assertNotExists(
      app.buttons["profile.logout"],
      name: "other-profile-logout-hidden",
      in: app,
      screenshotDir: screenshotDir
    )
    assertNotExists(
      app.buttons["profile.sidekicksCard"],
      name: "other-profile-sidekicks-card-hidden",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.staticTexts["profile.sharedAdventuresHeading"],
      name: "other-profile-shared-adventures-heading",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["feed.card.adventure-sarah-cliffs"],
      name: "other-profile-public-adventure-card",
      in: app,
      screenshotDir: screenshotDir
    )

    app.buttons["profile.back"].tap()
    assertExists(
      app.buttons["profile.sidekicksCard"],
      name: "self-profile-sidekicks-card-restored",
      in: app,
      screenshotDir: screenshotDir
    )
  }
}
