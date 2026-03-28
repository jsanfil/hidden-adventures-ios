import Foundation

protocol AdventureService {
  func listFeed(
    viewerHandle: String?,
    limit: Int,
    offset: Int
  ) async throws -> FeedResponse

  func getAdventure(
    id: UUID,
    viewerHandle: String?
  ) async throws -> AdventureDetailResponse
}

struct MockAdventureService: AdventureService {
  func listFeed(
    viewerHandle: String?,
    limit: Int,
    offset: Int
  ) async throws -> FeedResponse {
    let items = Array(MockFixtures.feedItems.dropFirst(offset).prefix(limit))
    return FeedResponse(
      items: items,
      paging: Paging(limit: limit, offset: offset, returned: items.count)
    )
  }

  func getAdventure(
    id: UUID,
    viewerHandle: String?
  ) async throws -> AdventureDetailResponse {
    if let detail = MockFixtures.adventureDetails[id] {
      return AdventureDetailResponse(item: detail)
    }

    throw MockServiceError.notFound
  }
}

enum MockServiceError: Error {
  case notFound
}
