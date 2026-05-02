import XCTest
@testable import HiddenAdventures

final class InviteFriendsCopyTests: XCTestCase {
  func testInviteMessageIncludesAppNameAndURL() {
    let url = URL(string: "https://hiddenadventures.app/invite")!

    let message = InviteFriendsCopy.inviteMessage(appURL: url)

    XCTAssertTrue(message.contains("Hidden Adventures"))
    XCTAssertTrue(message.contains(url.absoluteString))
  }

  func testFixtureInviteMessageMatchesInviteCopyHelper() {
    XCTAssertEqual(
      MockFixtures.inviteMessage,
      InviteFriendsCopy.inviteMessage(appURL: MockFixtures.inviteAppURL)
    )
  }
}
