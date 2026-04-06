import Foundation

struct AdventureDetailScreenModel: Identifiable, Equatable, Sendable {
  struct Author: Equatable, Sendable {
    let displayName: String
    let subtitle: String
    let initials: String
  }

  struct Comment: Identifiable, Equatable, Sendable {
    let id: String
    let authorDisplayName: String
    let authorInitials: String
    let relativeTimestamp: String
    let body: String
  }

  struct Directions: Equatable, Sendable {
    let latitude: Double
    let longitude: Double
  }

  let id: String
  let title: String
  let categoryLabel: String?
  let placeLabel: String
  let aboutLines: [String]
  let heroImageNames: [String]
  let averageRating: Double
  let ratingCount: Int
  let author: Author
  let directions: Directions?
  let commentsHeaderCount: Int
  let comments: [Comment]
}

enum AdventureDetailFixtureVariant: String, CaseIterable, Sendable {
  case happy
  case longText = "long-text"
  case singleImage = "single-image"
  case noComments = "no-comments"

  static func resolve(from environment: [String: String] = ProcessInfo.processInfo.environment) -> Self {
    guard let rawValue = environment["UITEST_DETAIL_VARIANT"]?.lowercased() else {
      return .happy
    }

    return Self(rawValue: rawValue) ?? .happy
  }
}

extension AdventureDetailScreenModel {
  init(detail: AdventureDetail, heroImageNames: [String], comments: [Comment]) {
    let displayName = detail.author.displayName ?? detail.author.handle
    let locationSubtitle = [detail.author.homeCity, detail.author.homeRegion]
      .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: ", ")
    let subtitlePrefix = locationSubtitle.isEmpty ? "Hidden Adventures" : locationSubtitle
    let aboutLines = [detail.summary, detail.body]
      .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }

    self.id = detail.id
    self.title = detail.title
    self.categoryLabel = detail.categoryLabel ?? detail.categorySlug?.displayTitle
    self.placeLabel = detail.placeLabel ?? "Hidden location"
    self.aboutLines = aboutLines.isEmpty ? ["No description yet."] : aboutLines
    self.heroImageNames = heroImageNames
    self.averageRating = detail.stats.averageRating
    self.ratingCount = detail.stats.ratingCount
    self.author = Author(
      displayName: displayName,
      subtitle: "\(subtitlePrefix) · 48 adventures",
      initials: Self.initials(for: displayName)
    )
    if let location = detail.location {
      self.directions = Directions(
        latitude: location.latitude,
        longitude: location.longitude
      )
    } else {
      self.directions = nil
    }
    self.commentsHeaderCount = comments.count
    self.comments = comments
  }

  static func initials(for name: String) -> String {
    let letters = name
      .split(separator: " ")
      .prefix(2)
      .compactMap(\.first)
      .map { String($0).uppercased() }
      .joined()

    return letters.isEmpty ? "HA" : letters
  }
}
