import Foundation

enum InviteFriendsPermissionState: Equatable {
  case notDetermined
  case authorized
  case denied
  case restricted
}

struct InviteFriendContact: Identifiable, Equatable, Sendable {
  let id: String
  let displayName: String
  let phoneNumber: String
}

enum InviteComposerResult: Equatable, Sendable {
  case sent(Int)
  case cancelled
  case failed
}

enum InviteFriendsCopy {
  static func inviteMessage(appURL: URL) -> String {
    "Join me on Hidden Adventures to swap hidden gems and weekend plans.\n\(appURL.absoluteString)"
  }
}
