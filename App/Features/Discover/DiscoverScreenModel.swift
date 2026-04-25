import Foundation

struct DiscoverScreenModel: Equatable, Sendable {
  let adventurers: [Adventurer]
  let popularAdventures: [Adventure]
  let emptyStateTitle: String
  let emptyStateSubtitle: String

  init(
    adventurers: [Adventurer],
    popularAdventures: [Adventure],
    emptyStateTitle: String = "No results yet",
    emptyStateSubtitle: String = "Try a different person or adventure title."
  ) {
    self.adventurers = adventurers
    self.popularAdventures = popularAdventures
    self.emptyStateTitle = emptyStateTitle
    self.emptyStateSubtitle = emptyStateSubtitle
  }

  func searchResults(for query: String) -> SearchResults {
    let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    guard normalizedQuery.isEmpty == false else {
      return SearchResults(people: [], adventures: [], query: "")
    }

    return SearchResults(
      people: adventurers.filter { adventurer in
        adventurer.name.lowercased().contains(normalizedQuery)
          || adventurer.handle.lowercased().contains(normalizedQuery)
      },
      adventures: popularAdventures.filter { adventure in
        adventure.title.lowercased().contains(normalizedQuery)
      },
      query: query
    )
  }

  struct Adventurer: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let handle: String
    let location: String?
    let adventureCount: Int
    let topCategories: [String]
    let coverImageNames: [String]
    let avatarImageName: String?

    var initials: String {
      name
        .split(separator: " ")
        .prefix(2)
        .compactMap(\.first)
        .map(String.init)
        .joined()
        .uppercased()
    }

    var displayHandle: String {
      handle.hasPrefix("@") ? handle : "@\(handle)"
    }
  }

  struct Adventure: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let authorName: String
    let location: String?
    let category: String
    let rating: Double?
    let favoriteCount: Int
    let imageNames: [String]
  }

  struct SearchResults: Equatable, Sendable {
    let people: [Adventurer]
    let adventures: [Adventure]
    let query: String

    var isEmpty: Bool {
      people.isEmpty && adventures.isEmpty
    }
  }
}

enum DiscoverFixtureVariant: String, CaseIterable, Equatable, Sendable {
  case happy
  case longText
  case empty

  static func resolve(environment: [String: String] = ProcessInfo.processInfo.environment) -> Self {
    guard let rawValue = environment["DISCOVER_FIXTURE_VARIANT"] else {
      return .happy
    }

    return Self(rawValue: rawValue) ?? .happy
  }
}
