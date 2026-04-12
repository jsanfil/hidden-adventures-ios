import XCTest

final class ProfileScreenUITests: HiddenAdventuresUITestCase {
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
      app.staticTexts["profile.stat.likes-received"].firstMatch,
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
      app.otherElements["sidekicks.row.sarahc"],
      name: "sidekicks-row-sarah",
      in: app,
      screenshotDir: screenshotDir
    )

    let searchField = app.textFields["sidekicks.searchField"]
    searchField.tap()
    searchField.typeText("mi")

    assertExists(
      app.otherElements["sidekicks.row.mikerod"],
      name: "sidekicks-row-mike",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.otherElements["sidekicks.row.jamiel"],
      name: "sidekicks-row-jamie",
      in: app,
      screenshotDir: screenshotDir
    )
    assertNotExists(
      app.otherElements["sidekicks.row.sarahc"],
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
}
