import XCTest
@testable import HiddenAdventures

final class DiscoverScreenModelTests: XCTestCase {
  func testAdventurerAvatarAccessibilityIdentifierUsesRemoteVariantWhenMediaExists() {
    let adventurer = DiscoverScreenModel.Adventurer(
      id: "adventurer-maya",
      name: "Maya Reyes",
      handle: "mayaexplores",
      location: "Portland, OR",
      adventureCount: 4,
      topCategories: ["Trails"],
      coverImageNames: [],
      avatarImageName: nil,
      coverMediaIDs: [],
      avatarMediaID: "media-avatar"
    )

    XCTAssertEqual(adventurer.avatarAccessibilityIdentifier, "discover.avatar.remote.media-avatar")
  }

  func testAdventurerAvatarFallbackUsesStrongerContrastTreatment() {
    let adventurer = DiscoverScreenModel.Adventurer(
      id: "adventurer-theo",
      name: "Theo Nakamura",
      handle: "theo.outdoors",
      location: "Bend, OR",
      adventureCount: 8,
      topCategories: ["Viewpoints"],
      coverImageNames: [],
      avatarImageName: nil
    )

    XCTAssertEqual(adventurer.fallbackAvatarBackgroundOpacity, 0.28)
  }

  func testSearchMatchesPeopleByNameAndHandleOnly() {
    let model = MockFixtures.discoverScreenModel()

    XCTAssertEqual(model.searchResults(for: "maya").people.map(\.id), ["adventurer-maya-reyes"])
    XCTAssertEqual(model.searchResults(for: "theo.outdoors").people.map(\.id), ["adventurer-theo-nakamura"])
    XCTAssertTrue(model.searchResults(for: "Portland").people.isEmpty)
  }

  func testSearchMatchesAdventuresByTitleOnly() {
    let model = MockFixtures.discoverScreenModel()

    XCTAssertEqual(
      model.searchResults(for: "gorge").adventures.map(\.id),
      [MockFixtures.oneontaID]
    )
    XCTAssertTrue(model.searchResults(for: "Hidden Gem").adventures.isEmpty)
    XCTAssertTrue(model.searchResults(for: "Columbia River").adventures.isEmpty)
  }

  func testEmptyVariantKeepsDeterministicEmptyState() {
    let model = MockFixtures.discoverScreenModel(for: .empty)
    let results = model.searchResults(for: "anything")

    XCTAssertTrue(model.adventurers.isEmpty)
    XCTAssertTrue(model.popularAdventures.isEmpty)
    XCTAssertTrue(results.isEmpty)
    XCTAssertEqual(model.emptyStateTitle, "No matches")
  }
}
