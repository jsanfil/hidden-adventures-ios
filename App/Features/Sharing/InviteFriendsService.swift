import Foundation
import MessageUI

protocol InviteFriendsService {
  func permissionState() async -> InviteFriendsPermissionState
  func requestAccess() async -> InviteFriendsPermissionState
  func loadContacts() async throws -> [InviteFriendContact]
  func canSendTextMessages() -> Bool
}

struct FixtureInviteFriendsService: InviteFriendsService {
  let permission: InviteFriendsPermissionState
  private let environment: [String: String]

  init(environment: [String: String] = ProcessInfo.processInfo.environment) {
    self.environment = environment

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

  func canSendTextMessages() -> Bool {
    if let override = environment["UITEST_CAN_SEND_TEXT_MESSAGES"]?.lowercased() {
      return override == "true"
    }

    return MFMessageComposeViewController.canSendText()
  }
}
