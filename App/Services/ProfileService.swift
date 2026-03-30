import Foundation

struct ProfileBootstrapDraft: Sendable {
  var displayName: String
  var handle: String
  var homeBase: String
  var bio: String
  var initials: String
}

protocol ProfileService {
  func getProfile(
    handle: String,
    limit: Int,
    offset: Int
  ) async throws -> ProfileResponse
}

struct FixtureProfileService: ProfileService {
  func getProfile(
    handle: String,
    limit: Int,
    offset: Int
  ) async throws -> ProfileResponse {
    guard handle == MockFixtures.profile.handle else {
      throw FixtureServiceError.notFound
    }

    let adventures = Array(MockFixtures.feedItems.dropFirst(offset).prefix(limit))
    return ProfileResponse(
      profile: MockFixtures.profile,
      adventures: adventures,
      paging: Paging(limit: limit, offset: offset, returned: adventures.count)
    )
  }
}

struct RemoteProfileService: ProfileService {
  let client: APIClient

  func getProfile(
    handle: String,
    limit: Int,
    offset: Int
  ) async throws -> ProfileResponse {
    try await client.get(
      pathComponents: ["profiles", handle],
      queryItems: [
        URLQueryItem(name: "limit", value: String(limit)),
        URLQueryItem(name: "offset", value: String(offset))
      ],
      requiresAuth: true
    )
  }
}
