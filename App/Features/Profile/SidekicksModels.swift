import Foundation

struct ProfileStatsSnapshot: Sendable {
  let adventures: Int
  let likesReceived: Int
  let views: Int
}

struct SidekickUser: Identifiable, Hashable, Sendable {
  let id: String
  let name: String
  let handle: String
  let location: String
  let adventuresCount: Int
  let avatarMediaID: String?

  var initials: String {
    let letters = name
      .split(separator: " ")
      .prefix(2)
      .compactMap(\.first)
      .map { String($0).uppercased() }
      .joined()

    return letters.isEmpty ? "HA" : letters
  }
}

enum SidekicksTab: String, CaseIterable, Identifiable, CustomStringConvertible {
  case mySidekicks = "My Sidekicks"
  case findUsers = "Find Users"

  var id: Self { self }
  var description: String { rawValue }
}

extension SidekickUser {
  var profile: SidekickProfileSummary {
    SidekickProfileSummary(
      id: id,
      handle: handle,
      displayName: name,
      bio: nil,
      homeCity: location.components(separatedBy: ",").first.map {
        $0.trimmingCharacters(in: .whitespacesAndNewlines)
      },
      homeRegion: location.components(separatedBy: ",").dropFirst().first.map {
        $0.trimmingCharacters(in: .whitespacesAndNewlines)
      },
      avatar: avatarMediaID.map { MediaReference(id: $0, storageKey: $0) },
      cover: nil
    )
  }

  func sidekickItem(isSidekick: Bool) -> SidekickListItem {
    SidekickListItem(
      profile: profile,
      relationship: SidekickRelationship(isSidekick: isSidekick),
      stats: SidekickStats(adventuresCount: adventuresCount)
    )
  }
}

protocol SidekickService: Sendable {
  func getMySidekicks(limit: Int, offset: Int) async throws -> MySidekicksResponse
  func getDiscoveredProfiles(limit: Int, offset: Int) async throws -> SidekickDiscoveryResponse
  func searchProfiles(query: String, limit: Int, offset: Int) async throws -> SidekickSearchResponse
  func addSidekick(handle: String) async throws -> SidekickMutationResponse
  func removeSidekick(handle: String) async throws -> SidekickMutationResponse
}

actor FixtureSidekickService: SidekickService {
  private var sidekickHandles: Set<String>

  init(initialSidekickIDs: Set<String> = MockFixtures.initialSidekickIDs) {
    sidekickHandles = Set(
      MockFixtures.sidekickUsers
        .filter { initialSidekickIDs.contains($0.id) }
        .map(\.handle)
    )
  }

  func getMySidekicks(limit: Int, offset: Int) async throws -> MySidekicksResponse {
    let items = activeItems().filter { $0.relationship.isSidekick }
    let pagedItems = Array(items.dropFirst(offset).prefix(limit))

    return MySidekicksResponse(
      items: pagedItems,
      paging: Paging(limit: limit, offset: offset, returned: pagedItems.count)
    )
  }

  func getDiscoveredProfiles(limit: Int, offset: Int) async throws -> SidekickDiscoveryResponse {
    let items = activeItems()
    let pagedItems = Array(items.dropFirst(offset).prefix(limit))

    return SidekickDiscoveryResponse(
      items: pagedItems,
      paging: Paging(limit: limit, offset: offset, returned: pagedItems.count)
    )
  }

  func searchProfiles(query: String, limit: Int, offset: Int) async throws -> SidekickSearchResponse {
    let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
    let items = activeItems().filter { item in
      item.profile.handle.localizedCaseInsensitiveContains(normalizedQuery) ||
        item.profile.displayName?.localizedCaseInsensitiveContains(normalizedQuery) == true ||
        item.profile.homeCity?.localizedCaseInsensitiveContains(normalizedQuery) == true ||
        item.profile.homeRegion?.localizedCaseInsensitiveContains(normalizedQuery) == true
    }
    let pagedItems = Array(items.dropFirst(offset).prefix(limit))

    return SidekickSearchResponse(
      items: pagedItems,
      paging: Paging(limit: limit, offset: offset, returned: pagedItems.count),
      query: normalizedQuery
    )
  }

  func addSidekick(handle: String) async throws -> SidekickMutationResponse {
    guard let user = MockFixtures.sidekickUsers.first(where: { $0.handle == handle }) else {
      throw APIError.server(statusCode: 404, message: "Profile not found.")
    }

    sidekickHandles.insert(user.handle)
    return SidekickMutationResponse(item: user.sidekickItem(isSidekick: true))
  }

  func removeSidekick(handle: String) async throws -> SidekickMutationResponse {
    guard let user = MockFixtures.sidekickUsers.first(where: { $0.handle == handle }) else {
      throw APIError.server(statusCode: 404, message: "Profile not found.")
    }

    sidekickHandles.remove(user.handle)
    return SidekickMutationResponse(item: user.sidekickItem(isSidekick: false))
  }

  private func activeItems() -> [SidekickListItem] {
    MockFixtures.sidekickUsers.map { user in
      let isSidekick = sidekickHandles.contains(user.handle)
      return SidekickListItem(
        profile: user.profile,
        relationship: SidekickRelationship(isSidekick: isSidekick),
        stats: SidekickStats(adventuresCount: user.adventuresCount)
      )
    }
  }
}

struct RemoteSidekickService: SidekickService {
  let client: APIClient

  func getMySidekicks(limit: Int, offset: Int) async throws -> MySidekicksResponse {
    try await client.get(
      pathComponents: ["me", "sidekicks"],
      queryItems: [
        URLQueryItem(name: "limit", value: String(limit)),
        URLQueryItem(name: "offset", value: String(offset))
      ],
      requiresAuth: true
    )
  }

  func getDiscoveredProfiles(limit: Int, offset: Int) async throws -> SidekickDiscoveryResponse {
    try await client.get(
      pathComponents: ["sidekicks", "discover"],
      queryItems: [
        URLQueryItem(name: "limit", value: String(limit)),
        URLQueryItem(name: "offset", value: String(offset))
      ],
      requiresAuth: true
    )
  }

  func searchProfiles(query: String, limit: Int, offset: Int) async throws -> SidekickSearchResponse {
    try await client.get(
      pathComponents: ["sidekicks", "search"],
      queryItems: [
        URLQueryItem(name: "q", value: query),
        URLQueryItem(name: "limit", value: String(limit)),
        URLQueryItem(name: "offset", value: String(offset))
      ],
      requiresAuth: true
    )
  }

  func addSidekick(handle: String) async throws -> SidekickMutationResponse {
    try await client.post(
      pathComponents: ["me", "sidekicks", handle],
      requiresAuth: true
    )
  }

  func removeSidekick(handle: String) async throws -> SidekickMutationResponse {
    try await client.delete(
      pathComponents: ["me", "sidekicks", handle],
      requiresAuth: true
    )
  }
}
