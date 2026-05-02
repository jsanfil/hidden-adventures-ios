import Foundation

enum Visibility: String, Codable, CaseIterable, Sendable {
  case `private`
  case sidekicks
  case `public`

  var displayTitle: String {
    switch self {
    case .private: "Only Me"
    case .sidekicks: "Sidekicks"
    case .public: "Public"
    }
  }
}

enum Category: String, Codable, CaseIterable, Identifiable, Sendable {
  case viewpoints
  case trails
  case waterSpots = "water_spots"
  case foodDrink = "food_drink"
  case abandonedPlaces = "abandoned_places"
  case caves
  case natureEscapes = "nature_escapes"
  case roadsideStops = "roadside_stops"

  var id: Self { self }

  var displayTitle: String {
    switch self {
    case .viewpoints: "Viewpoints"
    case .trails: "Trails"
    case .waterSpots: "Water Spots"
    case .foodDrink: "Food & Drink"
    case .abandonedPlaces: "Abandoned Places"
    case .caves: "Caves"
    case .natureEscapes: "Nature Escapes"
    case .roadsideStops: "Roadside Stops"
    }
  }

  var systemImage: String {
    switch self {
    case .viewpoints: "mountain.2"
    case .trails: "figure.hiking"
    case .waterSpots: "water.waves"
    case .foodDrink: "fork.knife"
    case .abandonedPlaces: "building.2"
    case .caves: "sparkle.magnifyingglass"
    case .natureEscapes: "leaf"
    case .roadsideStops: "location.north.line"
    }
  }
}

struct Paging: Codable, Sendable {
  let limit: Int
  let offset: Int
  let returned: Int
}

struct AdventureLocation: Codable, Hashable, Sendable {
  let latitude: Double
  let longitude: Double
}

struct FeedScope: Codable, Hashable, Sendable {
  let center: AdventureLocation
  let radiusMiles: Double
}

enum FeedSort: String, Codable, Sendable {
  case recent
  case distance
}

struct FeedQuery: Hashable, Sendable {
  let limit: Int
  let offset: Int
  let latitude: Double?
  let longitude: Double?
  let radiusMiles: Double?
  let sort: FeedSort?

  init(
    limit: Int,
    offset: Int,
    latitude: Double? = nil,
    longitude: Double? = nil,
    radiusMiles: Double? = nil,
    sort: FeedSort? = nil
  ) {
    self.limit = limit
    self.offset = offset
    self.latitude = latitude
    self.longitude = longitude
    self.radiusMiles = radiusMiles
    self.sort = sort
  }

  var isGeoScoped: Bool {
    latitude != nil && longitude != nil
  }

  var scope: FeedScope? {
    guard let latitude, let longitude, let radiusMiles else {
      return nil
    }

    return FeedScope(
      center: AdventureLocation(latitude: latitude, longitude: longitude),
      radiusMiles: radiusMiles
    )
  }
}

struct AdventureAuthor: Codable, Hashable, Sendable {
  let handle: String
  let displayName: String?
  let homeCity: String?
  let homeRegion: String?
}

struct AdventureCommentAuthor: Codable, Hashable, Sendable {
  let handle: String
  let displayName: String?
  let homeCity: String?
  let homeRegion: String?
  let avatar: MediaReference?
}

struct MediaReference: Codable, Hashable, Sendable {
  let id: String
  let storageKey: String
}

struct AdventureMediaItem: Codable, Hashable, Sendable {
  let id: String
  let sortOrder: Int
  let isPrimary: Bool
  let width: Int?
  let height: Int?
}

struct AdventureStats: Codable, Hashable, Sendable {
  let favoriteCount: Int
  let commentCount: Int
  let ratingCount: Int
  let averageRating: Double

  func favoriteCountAdjusted(isFavorited: Bool, wasFavorited: Bool) -> AdventureStats {
    let delta: Int
    switch (wasFavorited, isFavorited) {
    case (false, true):
      delta = 1
    case (true, false):
      delta = -1
    default:
      delta = 0
    }

    return AdventureStats(
      favoriteCount: max(0, favoriteCount + delta),
      commentCount: commentCount,
      ratingCount: ratingCount,
      averageRating: averageRating
    )
  }

  func ratingAdjusted(previousViewerRating: Int?, viewerRating: Int?) -> AdventureStats {
    let removedScore = previousViewerRating ?? 0
    let addedScore = viewerRating ?? 0
    let currentSum = averageRating * Double(ratingCount)
    let updatedCount = max(0, ratingCount - (previousViewerRating == nil ? 0 : 1) + (viewerRating == nil ? 0 : 1))
    let updatedSum = max(0, currentSum - Double(removedScore) + Double(addedScore))

    return AdventureStats(
      favoriteCount: favoriteCount,
      commentCount: commentCount,
      ratingCount: updatedCount,
      averageRating: updatedCount > 0 ? updatedSum / Double(updatedCount) : 0
    )
  }
}

struct AdventureCard: Codable, Identifiable, Hashable, Sendable {
  let id: String
  let title: String
  let description: String?
  let categorySlug: Category?
  let categoryLabel: String?
  let visibility: Visibility
  let createdAt: String
  let publishedAt: String?
  let location: AdventureLocation?
  let placeLabel: String?
  let author: AdventureAuthor
  let primaryMedia: MediaReference?
  let stats: AdventureStats
  let distanceMiles: Double?
  let isFavorited: Bool

  init(
    id: String,
    title: String,
    description: String?,
    categorySlug: Category?,
    categoryLabel: String?,
    visibility: Visibility,
    createdAt: String,
    publishedAt: String?,
    location: AdventureLocation?,
    placeLabel: String?,
    author: AdventureAuthor,
    primaryMedia: MediaReference?,
    stats: AdventureStats,
    distanceMiles: Double?,
    isFavorited: Bool = false
  ) {
    self.id = id
    self.title = title
    self.description = description
    self.categorySlug = categorySlug
    self.categoryLabel = categoryLabel
    self.visibility = visibility
    self.createdAt = createdAt
    self.publishedAt = publishedAt
    self.location = location
    self.placeLabel = placeLabel
    self.author = author
    self.primaryMedia = primaryMedia
    self.stats = stats
    self.distanceMiles = distanceMiles
    self.isFavorited = isFavorited
  }

  func applyingFavoriteState(_ isFavorited: Bool) -> AdventureCard {
    AdventureCard(
      id: id,
      title: title,
      description: description,
      categorySlug: categorySlug,
      categoryLabel: categoryLabel,
      visibility: visibility,
      createdAt: createdAt,
      publishedAt: publishedAt,
      location: location,
      placeLabel: placeLabel,
      author: author,
      primaryMedia: primaryMedia,
      stats: stats.favoriteCountAdjusted(isFavorited: isFavorited, wasFavorited: self.isFavorited),
      distanceMiles: distanceMiles,
      isFavorited: isFavorited
    )
  }

  func applyingRatingState(averageRating: Double, ratingCount: Int) -> AdventureCard {
    AdventureCard(
      id: id,
      title: title,
      description: description,
      categorySlug: categorySlug,
      categoryLabel: categoryLabel,
      visibility: visibility,
      createdAt: createdAt,
      publishedAt: publishedAt,
      location: location,
      placeLabel: placeLabel,
      author: author,
      primaryMedia: primaryMedia,
      stats: AdventureStats(
        favoriteCount: stats.favoriteCount,
        commentCount: stats.commentCount,
        ratingCount: ratingCount,
        averageRating: averageRating
      ),
      distanceMiles: distanceMiles,
      isFavorited: isFavorited
    )
  }
}

struct AdventureDetail: Codable, Identifiable, Hashable, Sendable {
  let id: String
  let title: String
  let description: String?
  let categorySlug: Category?
  let categoryLabel: String?
  let visibility: Visibility
  let createdAt: String
  let publishedAt: String?
  let location: AdventureLocation?
  let author: AdventureAuthor
  let primaryMedia: MediaReference?
  let stats: AdventureStats
  let placeLabel: String?
  let updatedAt: String
  let isFavorited: Bool
  let viewerRating: Int?

  init(
    id: String,
    title: String,
    description: String?,
    categorySlug: Category?,
    categoryLabel: String?,
    visibility: Visibility,
    createdAt: String,
    publishedAt: String?,
    location: AdventureLocation?,
    author: AdventureAuthor,
    primaryMedia: MediaReference?,
    stats: AdventureStats,
    placeLabel: String?,
    updatedAt: String,
    isFavorited: Bool = false,
    viewerRating: Int? = nil
  ) {
    self.id = id
    self.title = title
    self.description = description
    self.categorySlug = categorySlug
    self.categoryLabel = categoryLabel
    self.visibility = visibility
    self.createdAt = createdAt
    self.publishedAt = publishedAt
    self.location = location
    self.author = author
    self.primaryMedia = primaryMedia
    self.stats = stats
    self.placeLabel = placeLabel
    self.updatedAt = updatedAt
    self.isFavorited = isFavorited
    self.viewerRating = viewerRating
  }

  func applyingFavoriteState(_ isFavorited: Bool) -> AdventureDetail {
    AdventureDetail(
      id: id,
      title: title,
      description: description,
      categorySlug: categorySlug,
      categoryLabel: categoryLabel,
      visibility: visibility,
      createdAt: createdAt,
      publishedAt: publishedAt,
      location: location,
      author: author,
      primaryMedia: primaryMedia,
      stats: stats.favoriteCountAdjusted(isFavorited: isFavorited, wasFavorited: self.isFavorited),
      placeLabel: placeLabel,
      updatedAt: updatedAt,
      isFavorited: isFavorited,
      viewerRating: viewerRating
    )
  }

  func applyingViewerRating(_ viewerRating: Int?) -> AdventureDetail {
    AdventureDetail(
      id: id,
      title: title,
      description: description,
      categorySlug: categorySlug,
      categoryLabel: categoryLabel,
      visibility: visibility,
      createdAt: createdAt,
      publishedAt: publishedAt,
      location: location,
      author: author,
      primaryMedia: primaryMedia,
      stats: stats.ratingAdjusted(previousViewerRating: self.viewerRating, viewerRating: viewerRating),
      placeLabel: placeLabel,
      updatedAt: updatedAt,
      isFavorited: isFavorited,
      viewerRating: viewerRating
    )
  }
}

struct ProfileDetail: Codable, Identifiable, Hashable, Sendable {
  let id: String
  let handle: String
  let displayName: String?
  let bio: String?
  let homeCity: String?
  let homeRegion: String?
  let avatar: MediaReference?
  let cover: MediaReference?
  let createdAt: String
  let updatedAt: String
}

enum AuthAccountState: String, Codable, Sendable {
  case linked
  case legacyClaimed = "legacy_claimed"
  case newUserNeedsHandle = "new_user_needs_handle"
  case manualRecoveryRequired = "manual_recovery_required"
}

struct AuthBootstrapUser: Codable, Hashable, Sendable {
  let id: String
  let cognitoSubject: String?
  let handle: String
  let email: String?
  let accountOrigin: String
  let status: String
  let createdAt: String
  let updatedAt: String
}

struct AuthBootstrapResponse: Codable, Sendable {
  let accountState: AuthAccountState
  let user: AuthBootstrapUser?
  let suggestedHandle: String?
  let recoveryEmail: String?
}

struct FeedResponse: Codable, Sendable {
  let items: [AdventureCard]
  let paging: Paging
  let scope: FeedScope?
}

struct AdventureDetailResponse: Codable, Sendable {
  let item: AdventureDetail
}

struct AdventureMediaListResponse: Codable, Sendable {
  let items: [AdventureMediaItem]
}

struct AdventureCommentItem: Codable, Hashable, Identifiable, Sendable {
  let id: String
  let body: String
  let createdAt: String
  let updatedAt: String
  let author: AdventureCommentAuthor
}

struct AdventureCommentListResponse: Codable, Sendable {
  let items: [AdventureCommentItem]
  let paging: Paging
}

struct AdventureCommentCreateResponse: Codable, Sendable {
  let item: AdventureCommentItem
}

struct ProfileResponse: Codable, Sendable {
  let profile: ProfileDetail
  let adventures: [AdventureCard]
  let paging: Paging
}

struct ProfileFavoritesResponse: Codable, Sendable {
  let items: [AdventureCard]
  let paging: Paging
}

struct MeProfileResponse: Codable, Sendable {
  let profile: ProfileDetail
}

struct SidekickProfileSummary: Codable, Hashable, Sendable {
  let id: String
  let handle: String
  let displayName: String?
  let bio: String?
  let homeCity: String?
  let homeRegion: String?
  let avatar: MediaReference?
  let cover: MediaReference?
}

struct SidekickRelationship: Codable, Hashable, Sendable {
  let isSidekick: Bool
}

struct SidekickStats: Codable, Hashable, Sendable {
  let adventuresCount: Int
}

struct SidekickListItem: Codable, Identifiable, Hashable, Sendable {
  let profile: SidekickProfileSummary
  let relationship: SidekickRelationship
  let stats: SidekickStats

  var id: String { profile.id }
}

struct MySidekicksResponse: Codable, Sendable {
  let items: [SidekickListItem]
  let paging: Paging
}

struct SidekickDiscoveryResponse: Codable, Sendable {
  let items: [SidekickListItem]
  let paging: Paging
}

struct SidekickSearchResponse: Codable, Sendable {
  let items: [SidekickListItem]
  let paging: Paging
  let query: String
}

struct SidekickMutationResponse: Codable, Sendable {
  let item: SidekickListItem
}
