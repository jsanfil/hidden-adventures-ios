import Foundation

protocol AdventureService {
  func listFeed(
    limit: Int,
    offset: Int
  ) async throws -> FeedResponse

  func getAdventure(
    id: String
  ) async throws -> AdventureDetailResponse

  func listAdventureMedia(
    id: String
  ) async throws -> AdventureMediaListResponse

  func loadMediaData(
    id: String
  ) async throws -> Data
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
    id: String
  ) async throws -> AdventureDetailResponse {
    let resolvedID = MockFixtures.resolvedAdventureID(for: id)
    if let detail = MockFixtures.adventureDetails[resolvedID] {
      return AdventureDetailResponse(item: detail)
    }

    throw FixtureServiceError.notFound
  }

  func listAdventureMedia(
    id: String
  ) async throws -> AdventureMediaListResponse {
    AdventureMediaListResponse(items: MockFixtures.adventureMedia[MockFixtures.resolvedAdventureID(for: id)] ?? [])
  }

  func loadMediaData(
    id: String
  ) async throws -> Data {
    throw FixtureServiceError.notSupported
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
    id: String
  ) async throws -> AdventureDetailResponse {
    try await client.get(
      pathComponents: ["adventures", id],
      requiresAuth: true
    )
  }

  func listAdventureMedia(
    id: String
  ) async throws -> AdventureMediaListResponse {
    try await client.get(
      pathComponents: ["adventures", id, "media"],
      requiresAuth: true
    )
  }

  func loadMediaData(
    id: String
  ) async throws -> Data {
    if let cached = await MediaDataCache.shared.data(for: id) {
      return cached
    }

    let data = try await client.getData(
      pathComponents: ["media", id],
      requiresAuth: true
    )
    await MediaDataCache.shared.insert(data, for: id)
    return data
  }
}

enum FixtureServiceError: Error {
  case notFound
  case notSupported
}

actor MediaDataCache {
  static let shared = MediaDataCache()

  private var store: [String: Data] = [:]

  func data(for id: String) -> Data? {
    store[id]
  }

  func insert(_ data: Data, for id: String) {
    store[id] = data
  }
}
