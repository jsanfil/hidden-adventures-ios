import XCTest

final class ScreenGalleryRegressionUITests: HiddenAdventuresUITestCase {
  func testWelcome_galleryCapturesScreenshot() throws {
    try captureScreen(
      named: "gallery-welcome",
      startScreen: "welcome",
      expectedIdentifier: "welcome.getStarted"
    ) { app, directory in
      self.assertExists(
        app.buttons["welcome.signIn"],
        name: "welcome-sign-in",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.staticTexts["welcome.brandTitle"],
        name: "welcome-brand-title",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.staticTexts["welcome.headline"],
        name: "welcome-headline",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.staticTexts["welcome.subheadline"],
        name: "welcome-subheadline",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.staticTexts["welcome.legal"],
        name: "welcome-legal",
        in: app,
        screenshotDir: directory
      )
    }
  }

  func testProfile_galleryCapturesScreenshot() throws {
    try captureScreen(
      named: "gallery-profile",
      startScreen: "profile",
      expectedIdentifier: "profile.continue"
    ) { app, directory in
      self.assertExists(
        app.buttons["profile.back"],
        name: "profile-back",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.buttons["profile.skip"],
        name: "profile-skip",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.textFields["profile.displayName"],
        name: "profile-display-name",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.textFields["profile.handle"],
        name: "profile-handle",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.textFields["profile.homeCity"],
        name: "profile-home-city",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.textFields["profile.homeRegion"],
        name: "profile-home-region",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.textFields["profile.bio"],
        name: "profile-bio",
        in: app,
        screenshotDir: directory
      )
    }
  }

  func testExploreFeed_galleryCapturesScreenshot() throws {
    try captureScreen(
      named: "gallery-explore-feed",
      startScreen: "explore-feed",
      expectedIdentifier: "tab.home"
    ) { app, directory in
      self.assertExists(
        app.buttons["tab.explore"],
        name: "feed-explore-tab",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.buttons["header.search"],
        name: "feed-search-button",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.buttons["header.notifications"],
        name: "feed-notifications-button",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.buttons["tab.post"],
        name: "feed-post-tab",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.buttons["tab.saved"],
        name: "feed-saved-tab",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.buttons["tab.profile"],
        name: "feed-profile-tab",
        in: app,
        screenshotDir: directory
      )
      self.assertValue(
        app.buttons["tab.home"],
        equals: "selected",
        name: "feed-home-tab-selected",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.scrollViews["feed.scroll"],
        name: "feed-scroll",
        in: app,
        screenshotDir: directory
      )
      let categoryChips = app.buttons.matching(
        NSPredicate(format: "identifier BEGINSWITH %@", "explore.category.")
      )
      XCTAssertEqual(categoryChips.count, 8, "Expected exactly 8 category chips in Explore.")
    }
  }

  func testExploreMap_galleryCapturesScreenshot() throws {
    try captureScreen(
      named: "gallery-explore-map",
      startScreen: "explore-map",
      expectedIdentifier: "map.filterButton"
    ) { app, directory in
      self.assertExists(
        app.textFields["map.searchField"],
        name: "map-search-field",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.buttons["map.filterButton"],
        name: "map-filter-button",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.buttons["map.recenterButton"],
        name: "map-recenter-button",
        in: app,
        screenshotDir: directory
      )
      self.assertValue(
        app.buttons["tab.explore"],
        equals: "selected",
        name: "map-explore-tab-selected",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.buttons["map.pin.\(self.bluePoolID)"],
        name: "map-blue-pool-pin",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.staticTexts["map.sheet.count"],
        name: "map-sheet-count",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.staticTexts["map.card.title.blue-pool"],
        name: "map-blue-pool-title",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.staticTexts["map.card.title.opal-creek-trail"],
        name: "map-opal-creek-title",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.otherElements["map.card.image.blue-pool"],
        name: "map-blue-pool-image",
        in: app,
        screenshotDir: directory
      )
      self.assertHittable(
        app.buttons["map.card.\(self.bluePoolID)"],
        name: "map-blue-pool-card",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.buttons["map.sheet.modeButton"],
        name: "map-sheet-mode-button",
        in: app,
        screenshotDir: directory
      )
    }
  }

  func testCreatePhotos_galleryCapturesScreenshot() throws {
    try captureScreen(
      named: "gallery-create-photos",
      startScreen: "create-photos",
      expectedIdentifier: "create.next"
    ) { app, directory in
      self.assertExists(
        app.images["create.photoPreview"],
        name: "create-photo-preview",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.staticTexts["create.header.title"],
        name: "create-header-title",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.staticTexts["create.photoCount"],
        name: "create-photo-count",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.buttons["create.photoGrid.add"],
        name: "create-add-photo",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.buttons["create.photoGrid.hero-mountain"],
        name: "create-first-photo",
        in: app,
        screenshotDir: directory
      )
    }
  }

  func testCreateDetailsEmpty_galleryCapturesScreenshot() throws {
    try captureScreen(
      named: "gallery-create-details-empty",
      startScreen: "create-details-empty",
      expectedIdentifier: "create.post"
    ) { app, directory in
      self.assertExists(
        app.textFields["create.title"],
        name: "create-title",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.textFields["create.description"],
        name: "create-description",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.buttons["create.location.coordinatesButton"],
        name: "create-location-button",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.textFields["create.location.label"],
        name: "create-location-label",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.buttons["create.category.trails"],
        name: "create-category-trails",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.buttons["create.visibility.public"],
        name: "create-visibility-public",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.buttons["create.visibility.sidekicks"],
        name: "create-visibility-sidekicks",
        in: app,
        screenshotDir: directory
      )
    }
  }

  func testCreateDetailsLocation_galleryCapturesScreenshot() throws {
    try captureScreen(
      named: "gallery-create-details-location",
      startScreen: "create-details-location",
      expectedIdentifier: "create.post"
    ) { app, directory in
      self.assertExists(
        app.buttons["create.location.clearCoordinates"],
        name: "create-clear-coordinates",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.buttons["create.location.clearLabel"],
        name: "create-clear-label",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.staticTexts["create.location.helper"],
        name: "create-location-helper",
        in: app,
        screenshotDir: directory
      )
    }
  }

  func testCreateLocationOptions_galleryCapturesScreenshot() throws {
    try captureScreen(
      named: "gallery-create-location-options",
      startScreen: "create-location-options",
      expectedIdentifier: "create.locationSheet.searchPlaces"
    ) { app, directory in
      self.assertExists(
        app.staticTexts["create.locationSheet.title"],
        name: "create-location-sheet-title",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.buttons["create.locationSheet.currentLocation"],
        name: "create-current-location",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.buttons["create.locationSheet.dropPin"],
        name: "create-drop-pin",
        in: app,
        screenshotDir: directory
      )
    }
  }

  func testCreateLocationSearchEmpty_galleryCapturesScreenshot() throws {
    try captureScreen(
      named: "gallery-create-location-search-empty",
      startScreen: "create-location-search-empty",
      expectedIdentifier: "create.locationSheet.back"
    ) { app, directory in
      self.assertExists(
        app.textFields["create.locationSheet.searchField"],
        name: "create-search-field",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.staticTexts["create.locationSheet.searchEmpty"],
        name: "create-search-empty",
        in: app,
        screenshotDir: directory
      )
    }
  }

  func testCreateLocationSearchResults_galleryCapturesScreenshot() throws {
    try captureScreen(
      named: "gallery-create-location-search-results",
      startScreen: "create-location-search-results",
      expectedIdentifier: "create.locationSheet.result.yosemite"
    ) { app, directory in
      self.assertExists(
        app.textFields["create.locationSheet.searchField"],
        name: "create-search-field-results",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.buttons["create.locationSheet.result.yosemite"],
        name: "create-search-result-yosemite",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.buttons["create.locationSheet.result.crater-lake"],
        name: "create-search-result-crater",
        in: app,
        screenshotDir: directory
      )
    }
  }

  func testCreateLocationPin_galleryCapturesScreenshot() throws {
    try captureScreen(
      named: "gallery-create-location-pin",
      startScreen: "create-location-pin",
      expectedIdentifier: "create.locationSheet.confirmPin"
    ) { app, directory in
      self.assertExists(
        app.images["create.locationSheet.pinMap"],
        name: "create-pin-map",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.staticTexts["create.locationSheet.pinSummary"],
        name: "create-pin-summary",
        in: app,
        screenshotDir: directory
      )
    }
  }

  func testDetail_galleryCapturesScreenshot() throws {
    try captureScreen(
      named: "gallery-detail",
      startScreen: "detail",
      extraEnv: ["UITEST_DETAIL_ID": bluePoolID],
      expectedIdentifier: "detail.back"
    ) { app, directory in
      self.assertExists(
        app.staticTexts["detail.category"],
        name: "detail-category",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.staticTexts["detail.title"],
        name: "detail-title",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.staticTexts["detail.location"],
        name: "detail-location",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.staticTexts.matching(identifier: "detail.ratingSummary").firstMatch,
        name: "detail-rating-summary",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.staticTexts.matching(identifier: "detail.comments").firstMatch,
        name: "detail-comments",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.staticTexts["detail.description"],
        name: "detail-description",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.textFields["detail.composer"],
        name: "detail-composer",
        in: app,
        screenshotDir: directory
      )
      self.assertExists(
        app.buttons["detail.composer"],
        name: "detail-send",
        in: app,
        screenshotDir: directory
      )
    }
  }
}
