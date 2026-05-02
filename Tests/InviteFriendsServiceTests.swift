import MessageUI
import XCTest
@testable import HiddenAdventures

final class InviteFriendsServiceTests: XCTestCase {
  func testFixtureServiceDefaultsToSystemMessageCapability() {
    let service = FixtureInviteFriendsService(environment: [:])

    XCTAssertEqual(service.canSendTextMessages(), MFMessageComposeViewController.canSendText())
  }

  func testFixtureServiceHonorsUITestMessageCapabilityOverride() {
    XCTAssertFalse(
      FixtureInviteFriendsService(
        environment: ["UITEST_CAN_SEND_TEXT_MESSAGES": "false"]
      ).canSendTextMessages()
    )
    XCTAssertTrue(
      FixtureInviteFriendsService(
        environment: ["UITEST_CAN_SEND_TEXT_MESSAGES": "true"]
      ).canSendTextMessages()
    )
  }
}
