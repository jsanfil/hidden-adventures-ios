import Foundation

enum Visibility: String, Codable, CaseIterable, Sendable {
  case `private`
  case connections
  case `public`

  var displayTitle: String {
    switch self {
    case .private: "Only Me"
    case .connections: "Connections"
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

struct AdventureAuthor: Codable, Hashable, Sendable {
  let handle: String
  let displayName: String?
  let homeCity: String?
  let homeRegion: String?
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
}

struct AdventureCard: Codable, Identifiable, Hashable, Sendable {
  let id: String
  let title: String
  let summary: String?
  let body: String?
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
}

struct AdventureDetail: Codable, Identifiable, Hashable, Sendable {
  let id: String
  let title: String
  let summary: String?
  let body: String?
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
}

struct AdventureDetailResponse: Codable, Sendable {
  let item: AdventureDetail
}

struct AdventureMediaListResponse: Codable, Sendable {
  let items: [AdventureMediaItem]
}

struct ProfileResponse: Codable, Sendable {
  let profile: ProfileDetail
  let adventures: [AdventureCard]
  let paging: Paging
}

struct MeProfileResponse: Codable, Sendable {
  let profile: ProfileDetail
}
