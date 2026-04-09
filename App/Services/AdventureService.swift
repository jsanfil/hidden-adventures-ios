import Foundation
import UIKit

struct CreateAdventurePhotoUpload: Sendable {
  let data: Data
  let mimeType: String
  let width: Int?
  let height: Int?
}

struct CreateAdventureRequest: Sendable {
  let title: String
  let description: String?
  let categorySlug: Category?
  let visibility: Visibility
  let location: AdventureLocation?
  let placeLabel: String?
  let photos: [CreateAdventurePhotoUpload]
}

struct CreatedAdventureItem: Codable, Equatable, Sendable {
  let id: String
  let status: String
}

struct CreateAdventureResponse: Codable, Equatable, Sendable {
  let item: CreatedAdventureItem
}

private struct AdventureUploadAllocationRequest: Encodable {
  struct Item: Encodable {
    let clientId: String
    let mimeType: String
    let byteSize: Int
    let width: Int?
    let height: Int?
  }

  let items: [Item]
}

private struct AdventureUploadAllocationResponse: Decodable {
  struct Item: Decodable {
    struct Upload: Decodable {
      let method: String
      let url: String
      let headers: [String: String]
      let expiresAt: String
    }

    let clientId: String
    let mediaId: String
    let storageKey: String
    let upload: Upload
  }

  let items: [Item]
}

private struct AdventureCreatePayload: Encodable {
  struct Media: Encodable {
    let mediaId: String
    let sortOrder: Int
    let isPrimary: Bool
  }

  let title: String
  let description: String?
  let categorySlug: String?
  let visibility: String
  let location: AdventureLocation?
  let placeLabel: String?
  let media: [Media]
}

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

  func createAdventure(
    request: CreateAdventureRequest
  ) async throws -> CreateAdventureResponse
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

  func createAdventure(
    request: CreateAdventureRequest
  ) async throws -> CreateAdventureResponse {
    _ = request
    return CreateAdventureResponse(
      item: CreatedAdventureItem(
        id: UUID().uuidString.lowercased(),
        status: "pending_moderation"
      )
    )
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

  func createAdventure(
    request: CreateAdventureRequest
  ) async throws -> CreateAdventureResponse {
    let allocationRequest = AdventureUploadAllocationRequest(
      items: request.photos.enumerated().map { index, photo in
        AdventureUploadAllocationRequest.Item(
          clientId: "photo-\(index)",
          mimeType: photo.mimeType,
          byteSize: photo.data.count,
          width: photo.width,
          height: photo.height
        )
      }
    )

    let allocationResponse: AdventureUploadAllocationResponse = try await client.post(
      pathComponents: ["media", "adventure-uploads"],
      body: allocationRequest,
      requiresAuth: true
    )

    guard allocationResponse.items.count == request.photos.count else {
      throw APIError.invalidResponse
    }

    for (index, allocation) in allocationResponse.items.enumerated() {
      try await uploadPhoto(request.photos[index], target: allocation.upload)
    }

    let payload = AdventureCreatePayload(
      title: request.title,
      description: request.description,
      categorySlug: request.categorySlug?.rawValue,
      visibility: request.visibility.rawValue,
      location: request.location,
      placeLabel: request.placeLabel,
      media: allocationResponse.items.enumerated().map { index, item in
        AdventureCreatePayload.Media(
          mediaId: item.mediaId,
          sortOrder: index,
          isPrimary: index == 0
        )
      }
    )

    return try await client.post(
      pathComponents: ["adventures"],
      body: payload,
      requiresAuth: true
    )
  }

  private func uploadPhoto(
    _ photo: CreateAdventurePhotoUpload,
    target: AdventureUploadAllocationResponse.Item.Upload
  ) async throws {
    guard let url = URL(string: target.url) else {
      throw APIError.invalidBaseURL(target.url)
    }

    var uploadRequest = URLRequest(url: url)
    uploadRequest.httpMethod = target.method
    uploadRequest.httpBody = photo.data
    for (header, value) in target.headers {
      uploadRequest.setValue(value, forHTTPHeaderField: header)
    }

    let (_, response) = try await client.session.data(for: uploadRequest)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIError.invalidResponse
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
      throw APIError.server(
        statusCode: httpResponse.statusCode,
        message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
      )
    }
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
