import XCTest
@testable import HiddenAdventures

final class InviteFriendsScreenModelTests: XCTestCase {
  @MainActor
  func testSearchFiltersContactsByNameOrPhone() {
    let model = InviteFriendsScreenModel(
      permissionState: .authorized,
      contacts: [
        .init(id: "1", displayName: "Sarah Chen", phoneNumber: "5031112222"),
        .init(id: "2", displayName: "Mike Rodriguez", phoneNumber: "9713334444")
      ]
    )

    model.searchText = "sarah"
    XCTAssertEqual(model.visibleContacts.map(\.displayName), ["Sarah Chen"])

    model.searchText = "971"
    XCTAssertEqual(model.visibleContacts.map(\.displayName), ["Mike Rodriguez"])
  }

  @MainActor
  func testSelectionControlsInviteButtonState() {
    let model = InviteFriendsScreenModel(permissionState: .authorized, contacts: MockFixtures.inviteContacts)

    XCTAssertFalse(model.canSendInvites)

    model.toggleSelection(contactID: MockFixtures.inviteContacts[0].id)

    XCTAssertTrue(model.canSendInvites)
  }

  @MainActor
  func testInviteButtonDisablesWhenSelectionBecomesStaleAfterContactsRefresh() {
    let model = InviteFriendsScreenModel(permissionState: .authorized, contacts: MockFixtures.inviteContacts)

    model.toggleSelection(contactID: MockFixtures.inviteContacts[0].id)
    XCTAssertTrue(model.canSendInvites)

    model.contacts = [MockFixtures.inviteContacts[1], MockFixtures.inviteContacts[2]]

    XCTAssertTrue(model.selectedContacts.isEmpty)
    XCTAssertFalse(model.canSendInvites)
  }

  @MainActor
  func testSelectedContactsFollowContactsOrderingNotToggleOrdering() {
    let model = InviteFriendsScreenModel(permissionState: .authorized, contacts: MockFixtures.inviteContacts)

    model.toggleSelection(contactID: MockFixtures.inviteContacts[3].id)
    model.toggleSelection(contactID: MockFixtures.inviteContacts[1].id)

    XCTAssertEqual(
      model.selectedContacts.map(\.id),
      [MockFixtures.inviteContacts[1].id, MockFixtures.inviteContacts[3].id]
    )
  }

  @MainActor
  func testFallbackMessageExplainsContactsAccessAlternative() {
    let model = InviteFriendsScreenModel(permissionState: .denied, contacts: [])

    XCTAssertEqual(
      model.fallbackMessage,
      "Share Hidden Adventures with friends even if Contacts access is unavailable."
    )
  }
}
