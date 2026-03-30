import Foundation

protocol AdventureService {
  func listFeed(
    limit: Int,
    offset: Int
  ) async throws -> FeedResponse

  func getAdventure(
    id: UUID
  ) async throws -> AdventureDetailResponse
}

struct FixtureAdventureService: AdventureService {
  func listFeed(
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
    id: UUID
  ) async throws -> AdventureDetailResponse {
    if let detail = MockFixtures.adventureDetails[id] {
      return AdventureDetailResponse(item: detail)
    }

    throw FixtureServiceError.notFound
  }
}

struct RemoteAdventureService: AdventureService {
  let client: APIClient

  func listFeed(
    limit: Int,
    offset: Int
  ) async throws -> FeedResponse {
    try await client.get(
      pathComponents: ["feed"],
      queryItems: [
        URLQueryItem(name: "limit", value: String(limit)),
        URLQueryItem(name: "offset", value: String(offset))
      ],
      requiresAuth: true
    )
  }

  func getAdventure(
    id: UUID
  ) async throws -> AdventureDetailResponse {
    try await client.get(
      pathComponents: ["adventures", id.uuidString],
      requiresAuth: true
    )
  }
}

enum FixtureServiceError: Error {
  case notFound
}
