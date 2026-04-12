import Foundation

struct ProfileStatsSnapshot: Sendable {
  let adventures: Int
  let likesReceived: Int
  let views: Int
}

struct SidekickPreview: Identifiable, Hashable, Sendable {
  let id: String
  let name: String
  let initials: String
}

struct SidekickUser: Identifiable, Hashable, Sendable {
  let id: String
  let name: String
  let handle: String
  let location: String
  let adventuresCount: Int

  var initials: String {
    let letters = name
      .split(separator: " ")
      .prefix(2)
      .compactMap(\.first)
      .map { String($0).uppercased() }
      .joined()

    return letters.isEmpty ? "HA" : letters
  }
}

enum SidekicksTab: String, CaseIterable, Identifiable, CustomStringConvertible {
  case mySidekicks = "My Sidekicks"
  case findUsers = "Find Users"

  var id: Self { self }
  var description: String { rawValue }
}
