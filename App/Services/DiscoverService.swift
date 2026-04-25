import Foundation

protocol DiscoverService: Sendable {
  func home() async throws -> DiscoverScreenModel
  func search(query: String, limit: Int, offset: Int) async throws -> DiscoverScreenModel.SearchResults
}

struct FixtureDiscoverService: DiscoverService {
  let variant: DiscoverFixtureVariant

  init(variant: DiscoverFixtureVariant = .happy) {
    self.variant = variant
  }

  func home() async throws -> DiscoverScreenModel {
    MockFixtures.discoverScreenModel(for: variant)
  }

  func search(query: String, limit: Int, offset: Int) async throws -> DiscoverScreenModel.SearchResults {
    let model = MockFixtures.discoverScreenModel(for: variant)
    let results = model.searchResults(for: query)

    return DiscoverScreenModel.SearchResults(
      people: Array(results.people.dropFirst(offset).prefix(limit)),
      adventures: Array(results.adventures.dropFirst(offset).prefix(limit)),
      query: results.query
    )
  }
}

struct RemoteDiscoverService: DiscoverService {
  let client: APIClient

  func home() async throws -> DiscoverScreenModel {
    let response: DiscoverHomeResponse = try await client.get(
      pathComponents: ["discover", "home"],
      requiresAuth: true
    )

    return response.screenModel()
  }

  func search(query: String, limit: Int, offset: Int) async throws -> DiscoverScreenModel.SearchResults {
    let response: DiscoverSearchResponse = try await client.get(
      pathComponents: ["discover", "search"],
      queryItems: [
        URLQueryItem(name: "q", value: query),
        URLQueryItem(name: "limit", value: String(limit)),
        URLQueryItem(name: "offset", value: String(offset))
      ],
      requiresAuth: true
    )

    return response.searchResults()
  }
}

private struct DiscoverHomeResponse: Decodable {
  let modules: [DiscoverModule]

  func screenModel() -> DiscoverScreenModel {
    var adventurers: [DiscoverAdventurer] = []
    var adventures: [AdventureCard] = []

    for module in modules {
      switch module {
      case .adventurers(let items):
        adventurers = items
      case .adventures(let items):
        adventures = items
      }
    }

    return DiscoverScreenModel(
      adventurers: adventurers.map(\.screenModel),
      popularAdventures: adventures.map(\.discoverScreenModel)
    )
  }
}

private enum DiscoverModule: Decodable {
  case adventurers([DiscoverAdventurer])
  case adventures([AdventureCard])

  private enum CodingKeys: String, CodingKey {
    case type
    case items
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
    case "adventurers":
      self = .adventurers(try container.decode([DiscoverAdventurer].self, forKey: .items))
    case "adventures":
      self = .adventures(try container.decode([AdventureCard].self, forKey: .items))
    default:
      self = .adventurers([])
    }
  }
}

private struct DiscoverSearchResponse: Decodable {
  struct Bucket<Item: Decodable>: Decodable {
    let items: [Item]
    let paging: Paging
  }

  let query: String
  let people: Bucket<DiscoverAdventurer>
  let adventures: Bucket<AdventureCard>

  func searchResults() -> DiscoverScreenModel.SearchResults {
    DiscoverScreenModel.SearchResults(
      people: people.items.map(\.screenModel),
      adventures: adventures.items.map(\.discoverScreenModel),
      query: query
    )
  }
}

private struct DiscoverAdventurer: Decodable {
  let id: String
  let handle: String
  let displayName: String?
  let homeCity: String?
  let homeRegion: String?
  let avatar: MediaReference?
  let previewMedia: MediaReference?
  let publicAdventureCount: Int
  let topCategorySlugs: [String]

  var screenModel: DiscoverScreenModel.Adventurer {
    DiscoverScreenModel.Adventurer(
      id: id,
      name: displayName?.trimmedToNil ?? handle,
      handle: handle,
      location: [homeCity?.trimmedToNil, homeRegion?.trimmedToNil]
        .compactMap { $0 }
        .joined(separator: ", ")
        .trimmedToNil,
      adventureCount: publicAdventureCount,
      topCategories: topCategorySlugs.map(\.discoverCategoryLabel),
      coverImageNames: [],
      avatarImageName: nil,
      coverMediaIDs: previewMedia.map { [$0.id] } ?? [],
      avatarMediaID: avatar?.id
    )
  }
}

private extension AdventureCard {
  var discoverScreenModel: DiscoverScreenModel.Adventure {
    DiscoverScreenModel.Adventure(
      id: id,
      title: title,
      authorName: author.displayName?.trimmedToNil ?? author.handle,
      location: placeLabel?.trimmedToNil,
      category: categorySlug?.displayTitle ?? categoryLabel?.trimmedToNil ?? "Adventure",
      rating: stats.averageRating,
      favoriteCount: stats.favoriteCount,
      imageNames: [],
      mediaIDs: primaryMedia.map { [$0.id] } ?? []
    )
  }
}

private extension String {
  var trimmedToNil: String? {
    let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  var discoverCategoryLabel: String {
    if let category = Category(rawValue: self) {
      return category.displayTitle
    }

    return split(separator: "_")
      .map { part in
        part.prefix(1).uppercased() + part.dropFirst()
      }
      .joined(separator: " ")
  }
}
