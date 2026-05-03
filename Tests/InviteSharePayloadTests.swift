import XCTest
@testable import HiddenAdventures

final class InviteSharePayloadTests: XCTestCase {
  func testInvitePayloadIncludesAppNameAndURL() {
    let url = URL(string: "https://hiddenadventures.app/invite")!

    let payload = InviteSharePayload.make(appURL: url)

    XCTAssertTrue(payload.message.contains("Hidden Adventures"))
    XCTAssertTrue(payload.message.contains(url.absoluteString))
    XCTAssertEqual(payload.url, url)
  }

  func testFixtureInvitePayloadUsesSharedPayloadHelper() {
    XCTAssertEqual(MockFixtures.inviteAppURL, InviteSharePayload.make().url)
    XCTAssertEqual(MockFixtures.inviteMessage, InviteSharePayload.make().message)
  }
}
