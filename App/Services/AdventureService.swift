import Foundation
import CoreLocation
import OSLog
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

private struct AdventureCommentCreatePayload: Encodable {
  let body: String
}

private struct AdventureRatingUpsertPayload: Encodable {
  let score: Int
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
    query: FeedQuery
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

  func listComments(
    adventureID: String,
    limit: Int,
    offset: Int
  ) async throws -> AdventureCommentListResponse

  func createComment(
    adventureID: String,
    body: String
  ) async throws -> AdventureCommentCreateResponse

  func rateAdventure(
    id: String,
    score: Int
  ) async throws -> AdventureDetailResponse

  func clearRating(
    id: String
  ) async throws -> AdventureDetailResponse

  func createAdventure(
    request: CreateAdventureRequest
  ) async throws -> CreateAdventureResponse

  func favoriteAdventure(id: String) async throws
  func unfavoriteAdventure(id: String) async throws
}

struct FavoriteStateChange: Sendable {
  static let notificationName = Notification.Name("HiddenAdventuresFavoriteStateDidChange")
  static let adventureIDKey = "adventureID"
  static let isFavoritedKey = "isFavorited"

  let adventureID: String
  let isFavorited: Bool

  init?(notification: Notification) {
    guard
      let adventureID = notification.userInfo?[Self.adventureIDKey] as? String,
      let isFavorited = notification.userInfo?[Self.isFavoritedKey] as? Bool
    else {
      return nil
    }

    self.adventureID = adventureID
    self.isFavorited = isFavorited
  }

  static func post(adventureID: String, isFavorited: Bool) {
    NotificationCenter.default.post(
      name: notificationName,
      object: nil,
      userInfo: [
        adventureIDKey: adventureID,
        isFavoritedKey: isFavorited
      ]
    )
  }
}

struct RatingStateChange: Sendable, Equatable {
  static let notificationName = Notification.Name("HiddenAdventuresRatingStateDidChange")
  static let adventureIDKey = "adventureID"
  static let averageRatingKey = "averageRating"
  static let ratingCountKey = "ratingCount"
  static let viewerRatingKey = "viewerRating"

  let adventureID: String
  let averageRating: Double
  let ratingCount: Int
  let viewerRating: Int?

  init(
    adventureID: String,
    averageRating: Double,
    ratingCount: Int,
    viewerRating: Int?
  ) {
    self.adventureID = adventureID
    self.averageRating = averageRating
    self.ratingCount = ratingCount
    self.viewerRating = viewerRating
  }

  init?(notification: Notification) {
    guard
      let adventureID = notification.userInfo?[Self.adventureIDKey] as? String,
      let averageRating = notification.userInfo?[Self.averageRatingKey] as? Double,
      let ratingCount = notification.userInfo?[Self.ratingCountKey] as? Int
    else {
      return nil
    }

    self.init(
      adventureID: adventureID,
      averageRating: averageRating,
      ratingCount: ratingCount,
      viewerRating: notification.userInfo?[Self.viewerRatingKey] as? Int
    )
  }

  static func post(detail: AdventureDetail) {
    var userInfo: [String: Any] = [
      adventureIDKey: detail.id,
      averageRatingKey: detail.stats.averageRating,
      ratingCountKey: detail.stats.ratingCount
    ]
    userInfo[viewerRatingKey] = detail.viewerRating

    NotificationCenter.default.post(
      name: notificationName,
      object: nil,
      userInfo: userInfo
    )
  }
}

actor FavoriteFixtureStore {
  private var storedFavoriteIDs: Set<String>

  init(initialFavoriteIDs: Set<String>) {
    self.storedFavoriteIDs = initialFavoriteIDs
  }

  init(initialFavoriteIDs: [String]) {
    self.storedFavoriteIDs = Set(initialFavoriteIDs)
  }

  static func fromEnvironment(_ environment: [String: String] = ProcessInfo.processInfo.environment) -> FavoriteFixtureStore {
    switch environment["UITEST_PROFILE_FAVORITES"]?.lowercased() {
    case "empty":
      return FavoriteFixtureStore(initialFavoriteIDs: [])
    case "populated":
      return FavoriteFixtureStore(initialFavoriteIDs: [MockFixtures.bluePoolID])
    default:
      return FavoriteFixtureStore(initialFavoriteIDs: [MockFixtures.eagleID])
    }
  }

  func favoriteIDs() -> Set<String> {
    storedFavoriteIDs
  }

  func contains(_ id: String) -> Bool {
    storedFavoriteIDs.contains(id)
  }

  func favorite(id: String) throws {
    guard MockFixtures.adventureDetails[id] != nil else {
      throw FixtureServiceError.notFound
    }

    storedFavoriteIDs.insert(id)
    FavoriteStateChange.post(adventureID: id, isFavorited: true)
  }

  func unfavorite(id: String) throws {
    guard MockFixtures.adventureDetails[id] != nil else {
      throw FixtureServiceError.notFound
    }

    storedFavoriteIDs.remove(id)
    FavoriteStateChange.post(adventureID: id, isFavorited: false)
  }
}

actor CommentFixtureStore {
  private var storedCommentsByAdventureID: [String: [AdventureCommentItem]]
  private var nextOrdinal: Int

  init(
    initialCommentsByAdventureID: [String: [AdventureCommentItem]] = MockFixtures.detailCommentsByAdventureID
  ) {
    self.storedCommentsByAdventureID = initialCommentsByAdventureID
    self.nextOrdinal = initialCommentsByAdventureID.values.flatMap { $0 }.count + 1
  }

  func list(
    adventureID: String,
    limit: Int,
    offset: Int
  ) -> AdventureCommentListResponse {
    let comments = storedCommentsByAdventureID[adventureID] ?? []
    let items = Array(comments.dropFirst(offset).prefix(limit))
    return AdventureCommentListResponse(
      items: items,
      paging: Paging(limit: limit, offset: offset, returned: items.count)
    )
  }

  func create(
    adventureID: String,
    body: String
  ) throws -> AdventureCommentCreateResponse {
    guard MockFixtures.adventureDetails[adventureID] != nil else {
      throw FixtureServiceError.notFound
    }

    let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
    let item = AdventureCommentItem(
      id: "fixture-comment-\(nextOrdinal)",
      body: trimmedBody,
      createdAt: "2026-04-29T12:00:00Z",
      updatedAt: "2026-04-29T12:00:00Z",
      author: AdventureCommentAuthor(
        handle: MockFixtures.profile.handle,
        displayName: MockFixtures.profile.displayName,
        homeCity: MockFixtures.profile.homeCity,
        homeRegion: MockFixtures.profile.homeRegion,
        avatar: MockFixtures.profile.avatar
      )
    )
    nextOrdinal += 1
    storedCommentsByAdventureID[adventureID, default: []].append(item)
    return AdventureCommentCreateResponse(item: item)
  }
}

actor RatingFixtureStore {
  private var storedRatingsByAdventureID: [String: Int]

  init(initialRatingsByAdventureID: [String: Int] = [:]) {
    self.storedRatingsByAdventureID = initialRatingsByAdventureID
  }

  func rating(for adventureID: String) -> Int? {
    storedRatingsByAdventureID[adventureID]
  }

  func rate(adventureID: String, score: Int) throws -> Int {
    guard MockFixtures.adventureDetails[adventureID] != nil else {
      throw FixtureServiceError.notFound
    }

    storedRatingsByAdventureID[adventureID] = score
    return score
  }

  func clear(adventureID: String) throws {
    guard MockFixtures.adventureDetails[adventureID] != nil else {
      throw FixtureServiceError.notFound
    }

    storedRatingsByAdventureID.removeValue(forKey: adventureID)
  }
}

struct FixtureAdventureService: AdventureService {
  let favoriteStore: FavoriteFixtureStore
  let commentStore: CommentFixtureStore
  let ratingStore: RatingFixtureStore

  init(
    favoriteStore: FavoriteFixtureStore = FavoriteFixtureStore.fromEnvironment()
  ) {
    self.favoriteStore = favoriteStore
    self.commentStore = CommentFixtureStore()
    self.ratingStore = RatingFixtureStore()
  }

  init(
    favoriteStore: FavoriteFixtureStore,
    commentStore: CommentFixtureStore,
    ratingStore: RatingFixtureStore = RatingFixtureStore()
  ) {
    self.favoriteStore = favoriteStore
    self.commentStore = commentStore
    self.ratingStore = ratingStore
  }

  func listFeed(
    query: FeedQuery
  ) async throws -> FeedResponse {
    let favoriteIDs = await favoriteStore.favoriteIDs()
    let filteredItems = MockFixtures.feedItems
      .compactMap { item -> AdventureCard? in
        let item = item.applyingFavoriteState(favoriteIDs.contains(item.id))
        guard
          let scope = query.scope,
          let location = item.location
        else {
          return item
        }

        let distanceMiles = CLLocation(
          latitude: scope.center.latitude,
          longitude: scope.center.longitude
        ).distance(
          from: CLLocation(latitude: location.latitude, longitude: location.longitude)
        ) / 1_609.344

        guard distanceMiles <= scope.radiusMiles else {
          return nil
        }

        return AdventureCard(
          id: item.id,
          title: item.title,
          description: item.description,
          categorySlug: item.categorySlug,
          categoryLabel: item.categoryLabel,
          visibility: item.visibility,
          createdAt: item.createdAt,
          publishedAt: item.publishedAt,
          location: item.location,
          placeLabel: item.placeLabel,
          author: item.author,
          primaryMedia: item.primaryMedia,
          stats: item.stats,
          distanceMiles: Double(round(distanceMiles * 10) / 10),
          isFavorited: item.isFavorited
        )
      }

    let sortedItems: [AdventureCard]
    if query.scope != nil && query.sort == .distance {
      sortedItems = filteredItems.sorted { lhs, rhs in
        switch (lhs.distanceMiles, rhs.distanceMiles) {
        case let (.some(left), .some(right)):
          if left == right {
            return lhs.id > rhs.id
          }
          return left < right
        case (.some, .none):
          return true
        case (.none, .some):
          return false
        case (.none, .none):
          return lhs.id > rhs.id
        }
      }
    } else {
      sortedItems = filteredItems
    }

    let items = Array(sortedItems.dropFirst(query.offset).prefix(query.limit))
    return FeedResponse(
      items: items,
      paging: Paging(limit: query.limit, offset: query.offset, returned: items.count),
      scope: query.scope
    )
  }

  func getAdventure(
    id: String
  ) async throws -> AdventureDetailResponse {
    AdventureDetailResponse(item: try await hydratedDetail(id: id))
  }

  func listAdventureMedia(
    id: String
  ) async throws -> AdventureMediaListResponse {
    AdventureMediaListResponse(items: MockFixtures.adventureMedia[MockFixtures.resolvedAdventureID(for: id)] ?? [])
  }

  func loadMediaData(
    id: String
  ) async throws -> Data {
    guard let image = UIImage(named: id) else {
      throw FixtureServiceError.notSupported
    }

    if let data = image.jpegData(compressionQuality: 0.92) ?? image.pngData() {
      return data
    }

    throw FixtureServiceError.notSupported
  }

  func listComments(
    adventureID: String,
    limit: Int,
    offset: Int
  ) async throws -> AdventureCommentListResponse {
    let resolvedID = MockFixtures.resolvedAdventureID(for: adventureID)
    guard MockFixtures.adventureDetails[resolvedID] != nil else {
      throw FixtureServiceError.notFound
    }

    return await commentStore.list(
      adventureID: resolvedID,
      limit: limit,
      offset: offset
    )
  }

  func createComment(
    adventureID: String,
    body: String
  ) async throws -> AdventureCommentCreateResponse {
    try await commentStore.create(
      adventureID: MockFixtures.resolvedAdventureID(for: adventureID),
      body: body
    )
  }

  func rateAdventure(
    id: String,
    score: Int
  ) async throws -> AdventureDetailResponse {
    let resolvedID = MockFixtures.resolvedAdventureID(for: id)
    _ = try await ratingStore.rate(adventureID: resolvedID, score: score)
    let response = AdventureDetailResponse(item: try await hydratedDetail(id: resolvedID))
    RatingStateChange.post(detail: response.item)
    return response
  }

  func clearRating(
    id: String
  ) async throws -> AdventureDetailResponse {
    let resolvedID = MockFixtures.resolvedAdventureID(for: id)
    try await ratingStore.clear(adventureID: resolvedID)
    let response = AdventureDetailResponse(item: try await hydratedDetail(id: resolvedID))
    RatingStateChange.post(detail: response.item)
    return response
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

  func favoriteAdventure(id: String) async throws {
    try await favoriteStore.favorite(id: MockFixtures.resolvedAdventureID(for: id))
  }

  func unfavoriteAdventure(id: String) async throws {
    try await favoriteStore.unfavorite(id: MockFixtures.resolvedAdventureID(for: id))
  }

  private func hydratedDetail(id: String) async throws -> AdventureDetail {
    let resolvedID = MockFixtures.resolvedAdventureID(for: id)
    guard let detail = MockFixtures.adventureDetails[resolvedID] else {
      throw FixtureServiceError.notFound
    }

    let favoriteState = await favoriteStore.contains(resolvedID)
    let viewerRating = await ratingStore.rating(for: resolvedID)
    return detail
      .applyingFavoriteState(favoriteState)
      .applyingViewerRating(viewerRating)
  }
}

struct RemoteAdventureService: AdventureService {
  private static let logger = AppLogger.logger(category: "network.media")

  let client: APIClient
  let cache: MediaDataCache

  init(client: APIClient, cache: MediaDataCache = .shared) {
    self.client = client
    self.cache = cache
  }

  func listFeed(
    query: FeedQuery
  ) async throws -> FeedResponse {
    var queryItems = [
      URLQueryItem(name: "limit", value: String(query.limit)),
      URLQueryItem(name: "offset", value: String(query.offset))
    ]

    if let latitude = query.latitude {
      queryItems.append(URLQueryItem(name: "latitude", value: String(latitude)))
    }

    if let longitude = query.longitude {
      queryItems.append(URLQueryItem(name: "longitude", value: String(longitude)))
    }

    if let radiusMiles = query.radiusMiles {
      queryItems.append(URLQueryItem(name: "radiusMiles", value: String(radiusMiles)))
    }

    if let sort = query.sort {
      queryItems.append(URLQueryItem(name: "sort", value: sort.rawValue))
    }

    let response: FeedResponse = try await client.get(
      pathComponents: ["feed"],
      queryItems: queryItems,
      requiresAuth: true
    )
    return response
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
    switch await cache.lookup(id) {
    case .fresh(let data):
      Self.logger.info("Media cache hit (fresh) for mediaID=\(id, privacy: .public)")
      return data
    case .stale(let data, let entry):
      Self.logger.info("Media cache hit (stale) for mediaID=\(id, privacy: .public); starting background revalidation")
      triggerBackgroundRevalidation(mediaID: id, entry: entry)
      return data
    case .missing:
      Self.logger.info("Media cache miss for mediaID=\(id, privacy: .public); fetching from API")
      return try await loadOrJoinNetworkFetch(id: id)
    }
  }

  func listComments(
    adventureID: String,
    limit: Int,
    offset: Int
  ) async throws -> AdventureCommentListResponse {
    try await client.get(
      pathComponents: ["adventures", adventureID, "comments"],
      queryItems: [
        URLQueryItem(name: "limit", value: String(limit)),
        URLQueryItem(name: "offset", value: String(offset))
      ],
      requiresAuth: true
    )
  }

  func createComment(
    adventureID: String,
    body: String
  ) async throws -> AdventureCommentCreateResponse {
    let payload = AdventureCommentCreatePayload(
      body: body.trimmingCharacters(in: .whitespacesAndNewlines)
    )

    return try await client.post(
      pathComponents: ["adventures", adventureID, "comments"],
      body: payload,
      requiresAuth: true
    )
  }

  func rateAdventure(
    id: String,
    score: Int
  ) async throws -> AdventureDetailResponse {
    let response: AdventureDetailResponse = try await client.post(
      pathComponents: ["adventures", id, "rating"],
      body: AdventureRatingUpsertPayload(score: score),
      requiresAuth: true
    )
    RatingStateChange.post(detail: response.item)
    return response
  }

  func clearRating(
    id: String
  ) async throws -> AdventureDetailResponse {
    let response: AdventureDetailResponse = try await client.delete(
      pathComponents: ["adventures", id, "rating"],
      requiresAuth: true
    )
    RatingStateChange.post(detail: response.item)
    return response
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

  func favoriteAdventure(id: String) async throws {
    try await client.postNoContent(
      pathComponents: ["adventures", id, "favorite"],
      requiresAuth: true
    )
    FavoriteStateChange.post(adventureID: id, isFavorited: true)
  }

  func unfavoriteAdventure(id: String) async throws {
    try await client.deleteNoContent(
      pathComponents: ["adventures", id, "favorite"],
      requiresAuth: true
    )
    FavoriteStateChange.post(adventureID: id, isFavorited: false)
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

  private func loadOrJoinNetworkFetch(
    id: String
  ) async throws -> Data {
    if let existing = await cache.inFlightFetch(for: id) {
      return try await existing.value
    }

    let task = Task<Data, Error> {
      defer {
        Task {
          await cache.setInFlightFetch(nil, for: id)
        }
      }

      switch try await client.getMedia(
        pathComponents: ["media", id],
        requiresAuth: true
      ) {
      case .fetched(let response):
        try await cache.store(
          response.data,
          for: id,
          eTag: response.eTag,
          maxAgeSeconds: response.maxAgeSeconds,
          contentType: response.contentType
        )
        Self.logger.info("Media cache store for mediaID=\(id, privacy: .public) bytes=\(response.data.count, privacy: .public)")
        return response.data
      case .notModified:
        throw APIError.invalidResponse
      case .notFound:
        await cache.remove(id)
        MediaDataCache.postChange(mediaID: id, action: .invalidated)
        throw APIError.server(statusCode: 404, message: "Media not found.")
      }
    }

    await cache.setInFlightFetch(task, for: id)
    return try await task.value
  }

  private func triggerBackgroundRevalidation(
    mediaID: String,
    entry: MediaCacheEntry
  ) {
    Task {
      guard await cache.beginRevalidation(for: mediaID) else {
        return
      }

      defer {
        Task {
          await cache.endRevalidation(for: mediaID)
        }
      }

      do {
        switch try await client.getMedia(
          pathComponents: ["media", mediaID],
          ifNoneMatch: entry.eTag,
          requiresAuth: true
        ) {
        case .fetched(let response):
          try await cache.store(
            response.data,
            for: mediaID,
            eTag: response.eTag,
            maxAgeSeconds: response.maxAgeSeconds,
            contentType: response.contentType
          )
          MediaDataCache.postChange(mediaID: mediaID, action: .updated)
        case .notModified(let eTag, let maxAgeSeconds):
          try await cache.markRevalidated(
            mediaID,
            eTag: eTag,
            maxAgeSeconds: maxAgeSeconds
          )
        case .notFound:
          await cache.remove(mediaID)
          MediaDataCache.postChange(mediaID: mediaID, action: .invalidated)
        }
      } catch {
        Self.logger.error("Media revalidation failed for mediaID=\(mediaID, privacy: .public): \(error.localizedDescription, privacy: .public)")
      }
    }
  }
}

enum FixtureServiceError: Error {
  case notFound
  case notSupported
}
