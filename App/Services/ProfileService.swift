import Foundation

struct ProfileBootstrapDraft: Sendable {
  var displayName: String
  var handle: String
  var homeCity: String
  var homeRegion: String
  var bio: String
  var initials: String

  var updateRequest: MeProfileUpdateRequest {
    MeProfileUpdateRequest(
      displayName: displayName,
      bio: bio,
      homeCity: homeCity,
      homeRegion: homeRegion
    )
  }
}

struct MeProfileUpdateRequest: Encodable, Sendable {
  let displayName: String?
  let bio: String?
  let homeCity: String?
  let homeRegion: String?
}

protocol ProfileService {
  func getProfile(
    handle: String,
    limit: Int,
    offset: Int
  ) async throws -> ProfileResponse

  func getMyProfile() async throws -> MeProfileResponse
  func updateMyProfile(request: MeProfileUpdateRequest) async throws -> MeProfileResponse
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

  func getMyProfile() async throws -> MeProfileResponse {
    MeProfileResponse(profile: MockFixtures.profile)
  }

  func updateMyProfile(request: MeProfileUpdateRequest) async throws -> MeProfileResponse {
    let displayName = request.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
    let bio = request.bio?.trimmingCharacters(in: .whitespacesAndNewlines)
    let homeCity = request.homeCity?.trimmingCharacters(in: .whitespacesAndNewlines)
    let homeRegion = request.homeRegion?.trimmingCharacters(in: .whitespacesAndNewlines)

    return MeProfileResponse(
      profile: ProfileDetail(
        id: MockFixtures.profile.id,
        handle: MockFixtures.profile.handle,
        displayName: displayName?.isEmpty == false ? displayName : nil,
        bio: bio?.isEmpty == false ? bio : nil,
        homeCity: homeCity?.isEmpty == false ? homeCity : nil,
        homeRegion: homeRegion?.isEmpty == false ? homeRegion : nil,
        avatar: MockFixtures.profile.avatar,
        cover: MockFixtures.profile.cover,
        createdAt: MockFixtures.profile.createdAt,
        updatedAt: "2026-04-03T18:00:00Z"
      )
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

  func getMyProfile() async throws -> MeProfileResponse {
    try await client.get(
      pathComponents: ["me", "profile"],
      requiresAuth: true
    )
  }

  func updateMyProfile(request: MeProfileUpdateRequest) async throws -> MeProfileResponse {
    try await client.put(
      pathComponents: ["me", "profile"],
      body: request,
      requiresAuth: true
    )
  }
}
