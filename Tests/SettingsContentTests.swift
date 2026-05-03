import XCTest
@testable import HiddenAdventures

final class SettingsContentTests: XCTestCase {
  func testMainMenuItemsPreserveV0Order() {
    XCTAssertEqual(
      SettingsContent.mainMenuItems.map(\.destination),
      [.feedback, .terms, .privacy, .deleteAccount, .debugLogs]
    )
  }

  func testFeedbackCanSubmitRequiresTrimmedMessage() {
    XCTAssertFalse(SettingsFeedbackState.canSubmit(category: nil, message: "   "))
    XCTAssertTrue(SettingsFeedbackState.canSubmit(category: nil, message: "Found a bug"))
    XCTAssertTrue(SettingsFeedbackState.canSubmit(category: .bugReport, message: "  Found a bug  "))
  }
}
