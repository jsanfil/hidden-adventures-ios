import Foundation

protocol InviteFriendsService {
  func permissionState() async -> InviteFriendsPermissionState
  func requestAccess() async -> InviteFriendsPermissionState
  func loadContacts() async throws -> [InviteFriendContact]
  func canSendTextMessages() -> Bool
}

struct FixtureInviteFriendsService: InviteFriendsService {
  let permission: InviteFriendsPermissionState

  init(environment: [String: String] = ProcessInfo.processInfo.environment) {
    switch environment["UITEST_INVITE_PERMISSION"]?.lowercased() {
    case "denied":
      permission = .denied
    case "restricted":
      permission = .restricted
    case "not_determined":
      permission = .notDetermined
    default:
      permission = .authorized
    }
  }

  func permissionState() async -> InviteFriendsPermissionState { permission }

  func requestAccess() async -> InviteFriendsPermissionState {
    permission == .notDetermined ? .authorized : permission
  }

  func loadContacts() async throws -> [InviteFriendContact] { MockFixtures.inviteContacts }

  func canSendTextMessages() -> Bool { true }
}
