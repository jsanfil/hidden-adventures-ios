import XCTest

final class SettingsScreenUITests: HiddenAdventuresUITestCase {
  func testSettings_opensFromProfileAndRendersMainMenu() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "settings-main")
    let app = launchApp(startScreen: "explore-profile")

    let settingsButton = app.buttons["profile.settings"]
    assertHittable(
      settingsButton,
      name: "profile-settings-button",
      in: app,
      screenshotDir: screenshotDir
    )
    settingsButton.tap()

    assertExists(
      app.buttons["settings.back"],
      name: "settings-back",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["Give us feedback"],
      name: "settings-row-feedback",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["Terms of Service"],
      name: "settings-row-terms",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["Privacy Policy"],
      name: "settings-row-privacy",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["Delete Account"],
      name: "settings-row-delete-account",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["Upload Debug Logs"],
      name: "settings-row-debug-logs",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["settings.logout"],
      name: "settings-logout",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testSettings_feedbackSupportsCategoryEntryAndSubmit() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "settings-feedback")
    let app = launchApp(
      startScreen: "settings",
      extraEnv: ["UITEST_SETTINGS_SCREEN": "feedback"]
    )

    assertExists(
      app.staticTexts["settings.feedback.category"],
      name: "settings-feedback-category",
      in: app,
      screenshotDir: screenshotDir
    )
    assertExists(
      app.buttons["Bug Report"],
      name: "settings-feedback-category-option",
      in: app,
      screenshotDir: screenshotDir
    )
    app.buttons["Bug Report"].tap()

    let messageField = app.textViews["settings.feedback.message"]
    assertHittable(
      messageField,
      name: "settings-feedback-message",
      in: app,
      screenshotDir: screenshotDir
    )
    messageField.tap()
    messageField.typeText("The settings page looks great.")
    messageField.swipeUp()

    let submitButton = app.buttons["settings.feedback.submit"]
    assertHittable(
      submitButton,
      name: "settings-feedback-submit",
      in: app,
      screenshotDir: screenshotDir
    )
    submitButton.tap()

    assertExists(
      app.alerts["Feedback submitted"],
      name: "settings-feedback-alert",
      in: app,
      screenshotDir: screenshotDir
    )
  }

  func testSettings_termsAndPrivacyRenderLegalContent() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "settings-legal")

    let termsApp = launchApp(
      startScreen: "settings",
      extraEnv: ["UITEST_SETTINGS_SCREEN": "terms"]
    )
    assertExists(
      termsApp.buttons["settings.back"],
      name: "settings-terms-back",
      in: termsApp,
      screenshotDir: screenshotDir
    )
    assertExists(
      termsApp.staticTexts["settings.terms.title"],
      name: "settings-terms-title",
      in: termsApp,
      screenshotDir: screenshotDir
    )
    assertExists(
      termsApp.staticTexts["settings.terms.content"].firstMatch,
      name: "settings-terms-content",
      in: termsApp,
      screenshotDir: screenshotDir
    )
    termsApp.terminate()

    let privacyApp = launchApp(
      startScreen: "settings",
      extraEnv: ["UITEST_SETTINGS_SCREEN": "privacy"]
    )
    assertExists(
      privacyApp.staticTexts["settings.privacy.title"],
      name: "settings-privacy-title",
      in: privacyApp,
      screenshotDir: screenshotDir
    )
    assertExists(
      privacyApp.staticTexts["settings.privacy.content"].firstMatch,
      name: "settings-privacy-content",
      in: privacyApp,
      screenshotDir: screenshotDir
    )
  }

  func testSettings_deleteAndDebugLogsShowAlerts() throws {
    let screenshotDir = try preparedScreenshotDirectory(named: "settings-delete-debug")

    let deleteApp = launchApp(
      startScreen: "settings",
      extraEnv: ["UITEST_SETTINGS_SCREEN": "deleteAccount"]
    )
    let deleteButton = deleteApp.buttons["settings.delete.button"]
    assertHittable(
      deleteButton,
      name: "settings-delete-button",
      in: deleteApp,
      screenshotDir: screenshotDir
    )
    deleteButton.tap()
    deleteApp.sheets.buttons["Delete"].tap()
    assertExists(
      deleteApp.alerts["Delete Account"],
      name: "settings-delete-result",
      in: deleteApp,
      screenshotDir: screenshotDir
    )
    deleteApp.terminate()

    let debugApp = launchApp(startScreen: "settings")
    debugApp.buttons["Upload Debug Logs"].tap()
    assertExists(
      debugApp.alerts["Debug Logs Submitted"],
      name: "settings-debug-logs-alert",
      in: debugApp,
      screenshotDir: screenshotDir
    )
  }
}
