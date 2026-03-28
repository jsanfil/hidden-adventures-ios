import Foundation

struct ProfileBootstrapDraft: Sendable {
  var displayName: String
  var handle: String
  var homeBase: String
  var bio: String
  var initials: String
}

protocol ProfileService {
  func bootstrapDraft() async -> ProfileBootstrapDraft
  func getProfile(
    handle: String,
    viewerHandle: String?,
    limit: Int,
    offset: Int
  ) async throws -> ProfileResponse
}

struct MockProfileService: ProfileService {
  func bootstrapDraft() async -> ProfileBootstrapDraft {
    MockFixtures.bootstrapDraft
  }

  func getProfile(
    handle: String,
    viewerHandle: String?,
    limit: Int,
    offset: Int
  ) async throws -> ProfileResponse {
    guard handle == MockFixtures.profile.handle else {
      throw MockServiceError.notFound
    }

    let adventures = Array(MockFixtures.feedItems.dropFirst(offset).prefix(limit))
    return ProfileResponse(
      profile: MockFixtures.profile,
      adventures: adventures,
      paging: Paging(limit: limit, offset: offset, returned: adventures.count)
    )
  }
}
