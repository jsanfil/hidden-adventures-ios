import Foundation

@MainActor
final class InviteFriendsScreenModel: ObservableObject {
  @Published var permissionState: InviteFriendsPermissionState
  @Published var contacts: [InviteFriendContact]
  @Published var searchText = ""
  @Published private(set) var selectedContactIDs: Set<String> = []
  @Published var completionState: InviteComposerResult?

  init(permissionState: InviteFriendsPermissionState, contacts: [InviteFriendContact] = []) {
    self.permissionState = permissionState
    self.contacts = contacts
  }

  var visibleContacts: [InviteFriendContact] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard query.isEmpty == false else { return contacts }

    return contacts.filter {
      $0.displayName.lowercased().contains(query) || $0.phoneNumber.contains(query)
    }
  }

  var canSendInvites: Bool {
    permissionState == .authorized && selectedContacts.isEmpty == false
  }

  var selectedContacts: [InviteFriendContact] {
    contacts.filter { selectedContactIDs.contains($0.id) }
  }

  var fallbackMessage: String {
    "Share Hidden Adventures with friends even if Contacts access is unavailable."
  }

  func toggleSelection(contactID: String) {
    if selectedContactIDs.contains(contactID) {
      selectedContactIDs.remove(contactID)
    } else {
      selectedContactIDs.insert(contactID)
    }
  }

  func handleComposerResult(_ result: InviteComposerResult) {
    switch result {
    case .sent(let count):
      completionState = .sent(count)
      selectedContactIDs.removeAll()
    case .cancelled:
      completionState = .cancelled
    case .failed:
      completionState = .failed
    }
  }
}

extension InviteComposerResult {
  var title: String {
    switch self {
    case .sent(let count):
      return count == 1 ? "Invite sent to 1 friend." : "Invites sent to \(count) friends."
    case .cancelled:
      return "Invite cancelled."
    case .failed:
      return "We couldn't open Messages right now."
    }
  }
}
