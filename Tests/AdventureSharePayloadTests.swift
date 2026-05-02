import XCTest
@testable import HiddenAdventures

final class AdventureSharePayloadTests: XCTestCase {
  func testPublicAdventureBuildsSharePayload() {
    let detail = MockFixtures.sampleAdventureDetail(id: MockFixtures.eagleID, visibility: .public)

    let payload = AdventureSharePayload.make(
      detail: detail,
      baseURL: URL(string: "https://hiddenadventures.app")!
    )

    XCTAssertEqual(
      payload?.url.absoluteString,
      "https://hiddenadventures.app/adventures/\(MockFixtures.eagleID)"
    )
    XCTAssertTrue(payload?.message.contains("Eagle Creek Trail to Tunnel Falls") == true)
  }

  func testSidekicksAdventureIsNotExternallyShareable() {
    let detail = MockFixtures.sampleAdventureDetail(id: MockFixtures.bluePoolID, visibility: .sidekicks)

    XCTAssertNil(
      AdventureSharePayload.make(
        detail: detail,
        baseURL: URL(string: "https://hiddenadventures.app")!
      )
    )
    XCTAssertEqual(
      AdventureSharePayload.unavailableMessage(for: .sidekicks),
      "Only public adventures can be shared outside Hidden Adventures."
    )
  }
}
