import Foundation

protocol InviteFriendsService {
  func permissionState() async -> InviteFriendsPermissionState
  func requestAccess() async -> InviteFriendsPermissionState
  func loadContacts() async throws -> [InviteFriendContact]
  func canSendTextMessages() -> Bool
}

struct FixtureInviteFriendsService: InviteFriendsService {
  func permissionState() async -> InviteFriendsPermissionState { .authorized }

  func requestAccess() async -> InviteFriendsPermissionState { .authorized }

  func loadContacts() async throws -> [InviteFriendContact] { MockFixtures.inviteContacts }

  func canSendTextMessages() -> Bool { true }
}
