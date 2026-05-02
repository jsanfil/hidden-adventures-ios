import XCTest

final class InviteFriendsAvailabilityUITests: HiddenAdventuresUITestCase {
  func testInviteFriends_disablesMessagesCTAWhenDeviceCannotSendTexts() throws {
    let sarahContactID = "contact-sarah"
    let app = launchApp(
      startScreen: "explore-profile",
      extraEnv: [
        "UITEST_INVITE_PERMISSION": "authorized",
        "UITEST_CAN_SEND_TEXT_MESSAGES": "false"
      ]
    )

    app.buttons["profile.inviteFriends"].tap()
    XCTAssertTrue(app.buttons["inviteFriends.contact.\(sarahContactID)"].waitForExistence(timeout: 2))

    app.buttons["inviteFriends.contact.\(sarahContactID)"].tap()

    XCTAssertFalse(app.buttons["inviteFriends.cta"].isEnabled)
  }
}
