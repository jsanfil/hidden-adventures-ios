import XCTest
@testable import HiddenAdventures

final class AdventureDetailScreenModelTests: XCTestCase {
  func testInitCarriesViewerRatingFromDetail() {
    let detail = AdventureDetail(
      id: "adventure-1",
      title: "Blue Pool",
      description: "Cold water and a great swim.",
      categorySlug: .waterSpots,
      categoryLabel: "Hidden Gem",
      visibility: .public,
      createdAt: "2026-04-28T18:00:00.000Z",
      publishedAt: "2026-04-28T18:00:00.000Z",
      location: AdventureLocation(latitude: 44.0, longitude: -122.0),
      author: AdventureAuthor(
        handle: "mayaexplores",
        displayName: "Maya Reyes",
        homeCity: "Portland",
        homeRegion: "OR"
      ),
      primaryMedia: nil,
      stats: AdventureStats(favoriteCount: 10, commentCount: 4, ratingCount: 12, averageRating: 4.4),
      placeLabel: "Oregon",
      updatedAt: "2026-04-28T18:00:00.000Z",
      viewerRating: 5
    )

    let model = AdventureDetailScreenModel(
      detail: detail,
      heroImageNames: [],
      comments: []
    )

    XCTAssertEqual(model.viewerRating, 5)
  }

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

  func testAdventureCardApplyingRatingStateReplacesAggregateStatsOnly() {
    let card = AdventureCard(
      id: "adventure-1",
      title: "Blue Pool",
      description: "Cold water and a great swim.",
      categorySlug: .waterSpots,
      categoryLabel: "Hidden Gem",
      visibility: .public,
      createdAt: "2026-04-28T18:00:00.000Z",
      publishedAt: "2026-04-28T18:00:00.000Z",
      location: AdventureLocation(latitude: 44.0, longitude: -122.0),
      placeLabel: "Oregon",
      author: AdventureAuthor(
        handle: "mayaexplores",
        displayName: "Maya Reyes",
        homeCity: "Portland",
        homeRegion: "OR"
      ),
      primaryMedia: nil,
      stats: AdventureStats(favoriteCount: 10, commentCount: 4, ratingCount: 12, averageRating: 4.1),
      distanceMiles: 2.4,
      isFavorited: true
    )

    let updated = card.applyingRatingState(averageRating: 4.3, ratingCount: 13)

    XCTAssertEqual(updated.id, card.id)
    XCTAssertEqual(updated.title, card.title)
    XCTAssertEqual(updated.isFavorited, card.isFavorited)
    XCTAssertEqual(updated.stats.favoriteCount, 10)
    XCTAssertEqual(updated.stats.commentCount, 4)
    XCTAssertEqual(updated.stats.ratingCount, 13)
    XCTAssertEqual(updated.stats.averageRating, 4.3)
  }
}
