import XCTest
@testable import HiddenAdventures

final class AdventureDetailScreenModelTests: XCTestCase {
  func testCommentMappingPreservesAvatarMediaIDWhenPresent() {
    let comment = AdventureCommentItem(
      id: "comment-1",
      body: "Looks incredible.",
      createdAt: "2026-04-28T18:00:00.000Z",
      updatedAt: "2026-04-28T18:00:00.000Z",
      author: AdventureCommentAuthor(
        handle: "mayaexplores",
        displayName: "Maya Reyes",
        homeCity: "Portland",
        homeRegion: "OR",
        avatar: MediaReference(id: "media-avatar", storageKey: "media-avatar")
      )
    )

    let mapped = AdventureDetailScreenModel.comment(from: comment)

    XCTAssertEqual(mapped.authorHandle, "mayaexplores")
    XCTAssertEqual(mapped.authorDisplayName, "Maya Reyes")
    XCTAssertEqual(mapped.authorInitials, "MR")
    XCTAssertEqual(mapped.avatarMediaID, "media-avatar")
  }

  func testCommentMappingUsesProfileAvatarWhenCommentPayloadOmitsIt() {
    let comment = AdventureCommentItem(
      id: "comment-2",
      body: "Worth the hike.",
      createdAt: "2026-04-28T18:00:00.000Z",
      updatedAt: "2026-04-28T18:00:00.000Z",
      author: AdventureCommentAuthor(
        handle: "joedev",
        displayName: "Joe Dev",
        homeCity: "Denver",
        homeRegion: "CO",
        avatar: nil
      )
    )
    let profile = ProfileDetail(
      id: "profile-1",
      handle: "joedev",
      displayName: "Joe Dev",
      bio: nil,
      homeCity: "Denver",
      homeRegion: "CO",
      avatar: MediaReference(id: "viewer-avatar", storageKey: "viewer-avatar"),
      cover: nil,
      createdAt: "2026-04-01T00:00:00.000Z",
      updatedAt: "2026-04-02T00:00:00.000Z"
    )

    let mapped = AdventureDetailScreenModel.comment(from: comment, profile: profile)

    XCTAssertEqual(mapped.authorHandle, "joedev")
    XCTAssertEqual(mapped.authorDisplayName, "Joe Dev")
    XCTAssertEqual(mapped.authorInitials, "JD")
    XCTAssertEqual(mapped.avatarMediaID, "viewer-avatar")
  }
}
