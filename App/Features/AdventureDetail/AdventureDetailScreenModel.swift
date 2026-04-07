import Foundation

struct AdventureDetailScreenModel: Identifiable, Equatable, Sendable {
  struct Author: Equatable, Sendable {
    let handle: String
    let displayName: String
    let subtitle: String
    let initials: String
    let avatarMediaID: String?
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
  init(
    detail: AdventureDetail,
    heroImageNames: [String],
    comments: [Comment],
    authorProfile: ProfileDetail? = nil
  ) {
    let authorHandle = authorProfile?.handle ?? detail.author.handle
    let displayName = authorProfile?.displayName ?? detail.author.displayName ?? authorHandle
    let locationSubtitle = [authorProfile?.homeCity ?? detail.author.homeCity, authorProfile?.homeRegion ?? detail.author.homeRegion]
      .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
    let subtitleSegments = [locationSubtitle.joined(separator: ", "), "@\(authorHandle)"]
      .filter { !$0.isEmpty }
    let aboutLines = [detail.description]
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
      handle: authorHandle,
      displayName: displayName,
      subtitle: subtitleSegments.isEmpty ? "Hidden Adventures" : subtitleSegments.joined(separator: " · "),
      initials: Self.initials(for: displayName),
      avatarMediaID: authorProfile?.avatar?.id
    )
    if let location = detail.location {
      self.directions = Directions(
        latitude: location.latitude,
        longitude: location.longitude
      )
    } else {
      self.directions = nil
    }
    self.commentsHeaderCount = comments.isEmpty ? detail.stats.commentCount : comments.count
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
