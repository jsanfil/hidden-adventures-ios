# Adventure Sharing + Friend Invites Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a fixture-first iOS implementation for `Invite Friends` from Profile and `Share Adventure` from Adventure Detail, while keeping server dependency minimal and explicitly isolating the unresolved public-link integration work.

**Architecture:** Build this feature as two separate flows under a shared `Sharing` feature folder. `Invite Friends` gets its own navigation destination, permission-aware contact selection state, and SMS composer bridge; `Share Adventure` stays lightweight on Adventure Detail with a share payload builder plus visibility gating for non-public adventures. Keep all feature logic testable behind small protocols so fixture preview and UI automation can cover the full mock-first experience before any live deep-link contract is finalized.

**Tech Stack:** SwiftUI, UIKit bridges (`UIActivityViewController`, `MFMessageComposeViewController`), Contacts framework, generated Info.plist keys via `project.yml`, XCTest, XCUITest

---

## Why This Is The Correct Next iOS Slice

`Adventure Sharing + Friend Invites` is the current scheduled feature in [`../hidden-adventures-plan/master-plan.md`](/Users/josephsanfilippo/Documents/projects/hidden-adventures-rebuild/hidden-adventures-plan/master-plan.md) and the iOS repo is explicitly allowed to prioritize accepted-design, fixture-backed implementation first. The current codebase already has the correct entry seams:

- [`App/Features/Profile/ProfileView.swift`](/Users/josephsanfilippo/Documents/projects/hidden-adventures-rebuild/hidden-adventures-ios/App/Features/Profile/ProfileView.swift) owns the signed-in viewer’s growth-oriented profile actions.
- [`App/Features/AdventureDetail/AdventureDetailView.swift`](/Users/josephsanfilippo/Documents/projects/hidden-adventures-rebuild/hidden-adventures-ios/App/Features/AdventureDetail/AdventureDetailView.swift) already exposes a `detail.share` button that is still placeholder behavior.
- The app already prefers fixture-backed UI acceptance before live integration.

## Assumptions

- Use `https://hiddenadventures.app/adventures/{id}` as the provisional public adventure URL shape unless `hidden-adventures-plan` or server work publishes a different canonical host before implementation starts.
- `Invite Friends` remains viewer-only and lives behind the signed-in user’s own profile.
- SMS is the only first-party invite send path in v1; fallback for denied Contacts permission is a generic app-invite share/copy path, not manual in-app contact entry.
- The iOS slice may add app-local deep-link parsing hooks, but full universal-link reliability is not considered complete until the canonical host and associated-domain contract are approved cross-repo.

## File Structure

### New files

- `App/Features/Sharing/AdventureSharePayload.swift`
  Builds a shareable payload for public adventures and returns an unavailable reason for `sidekicks` or `private` adventures.
- `App/Features/Sharing/AdventureShareSheet.swift`
  SwiftUI wrapper around `UIActivityViewController` so Adventure Detail can present the native share sheet.
- `App/Features/Sharing/InviteFriendsModels.swift`
  Contact row model, permission state enum, composer result enum, and invite copy helpers.
- `App/Features/Sharing/InviteFriendsService.swift`
  Protocol plus fixture/live implementations for contacts permission, contact lookup, and SMS capability checks.
- `App/Features/Sharing/InviteFriendsScreenModel.swift`
  Search, selection, CTA enablement, fallback, and completion-state logic for the invite flow.
- `App/Features/Sharing/InviteFriendsView.swift`
  The dedicated Profile-launched invite flow.
- `App/Features/Sharing/InviteFriendsMessageComposer.swift`
  `MFMessageComposeViewController` bridge used by the invite flow.
- `Tests/AdventureSharePayloadTests.swift`
  Unit tests for public/private visibility behavior and generated payload content.
- `Tests/InviteFriendsScreenModelTests.swift`
  Unit tests for permission states, search, selection, fallback, and completion transitions.

### Modified files

- `App/AppCoordinator.swift`
  Add an `inviteFriends` route and optional UI-test launch route.
- `App/RootView.swift`
  Inject the new invite service and route to `InviteFriendsView`.
- `App/HiddenAdventuresApp.swift`
  Compose fixture/live `InviteFriendsService`.
- `App/Services/MockFixtures.swift`
  Add deterministic invite contact fixtures and generic app-invite copy.
- `App/Features/Profile/ProfileView.swift`
  Add the signed-in viewer `Invite Friends` entrypoint.
- `App/Features/AdventureDetail/AdventureDetailView.swift`
  Replace the placeholder share action with real visibility-aware share behavior.
- `project.yml`
  Add `NSContactsUsageDescription`.
- `UITests/Screens/ProfileScreenUITests.swift`
  Cover the invite flow states in fixture preview.
- `UITests/Screens/DetailScreenUITests.swift`
  Cover public-share availability and non-public share explanation states.

## Open Dependency To Keep Explicit

This repo can safely complete `Mock iOS accepted` without backend work. The exact integrated behavior for “shared link opens the installed app and otherwise lands somewhere stable” still depends on a cross-repo decision for:

- canonical public host/domain
- associated-domain entitlement setup
- any server/web fallback page behavior

Do not block the mock-first iOS slice on that decision, but do not silently mark universal-link behavior complete without it either.

### Task 1: Add Sharing Models And Service Seams

**Files:**
- Create: `App/Features/Sharing/AdventureSharePayload.swift`
- Create: `App/Features/Sharing/InviteFriendsModels.swift`
- Create: `App/Features/Sharing/InviteFriendsService.swift`
- Modify: `App/Services/MockFixtures.swift`
- Modify: `App/HiddenAdventuresApp.swift`
- Test: `Tests/AdventureSharePayloadTests.swift`
- Test: `Tests/InviteFriendsScreenModelTests.swift`

- [ ] **Step 1: Write the failing unit tests for share visibility and invite copy**

```swift
import XCTest
@testable import HiddenAdventures

final class AdventureSharePayloadTests: XCTestCase {
  func testPublicAdventureBuildsSharePayload() {
    let detail = MockFixtures.sampleAdventureDetail(id: MockFixtures.eagleID, visibility: .public)

    let payload = AdventureSharePayload.make(
      detail: detail,
      baseURL: URL(string: "https://hiddenadventures.app")!
    )

    XCTAssertEqual(payload?.url.absoluteString, "https://hiddenadventures.app/adventures/\(MockFixtures.eagleID)")
    XCTAssertTrue(payload?.message.contains("Eagle Creek Trail to Tunnel Falls") == true)
  }

  func testSidekicksAdventureIsNotExternallyShareable() {
    let detail = MockFixtures.sampleAdventureDetail(id: MockFixtures.bluePoolID, visibility: .sidekicks)
    XCTAssertNil(AdventureSharePayload.make(detail: detail, baseURL: URL(string: "https://hiddenadventures.app")!))
    XCTAssertEqual(AdventureSharePayload.unavailableMessage(for: .sidekicks), "Only public adventures can be shared outside Hidden Adventures.")
  }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
xcodebuild -project HiddenAdventures.xcodeproj -scheme HiddenAdventures -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HiddenAdventuresTests/AdventureSharePayloadTests test
```

Expected: FAIL because `AdventureSharePayload` and `MockFixtures.sampleAdventureDetail` do not exist yet.

- [ ] **Step 3: Add the minimal share payload model and fixture helpers**

```swift
import Foundation

struct AdventureSharePayload: Equatable {
  let url: URL
  let message: String

  static func make(detail: AdventureDetail, baseURL: URL) -> Self? {
    guard detail.visibility == .public else { return nil }
    let url = baseURL.appending(path: "adventures").appending(path: detail.id)
    let place = detail.placeLabel ?? "Hidden Adventures"
    return Self(
      url: url,
      message: "Check out \(detail.title) on Hidden Adventures\n\(place)\n\(url.absoluteString)"
    )
  }

  static func unavailableMessage(for visibility: Visibility) -> String {
    switch visibility {
    case .public:
      return ""
    case .sidekicks, .private:
      return "Only public adventures can be shared outside Hidden Adventures."
    }
  }
}
```

```swift
extension MockFixtures {
  static func sampleAdventureDetail(id: String, visibility: Visibility) -> AdventureDetail {
    let card = feedItems.first(where: { $0.id == resolvedAdventureID(for: id) }) ?? feedItems[0]
    return AdventureDetail(
      id: card.id,
      title: card.title,
      description: card.description,
      categorySlug: card.categorySlug,
      categoryLabel: card.categoryLabel,
      visibility: visibility,
      createdAt: card.createdAt,
      publishedAt: card.publishedAt,
      location: card.location,
      author: card.author,
      primaryMedia: card.primaryMedia,
      stats: card.stats,
      placeLabel: card.placeLabel,
      updatedAt: card.createdAt
    )
  }
}
```

- [ ] **Step 4: Add invite service protocols and deterministic fixtures**

```swift
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
```

- [ ] **Step 5: Run the focused tests and commit**

Run:

```bash
xcodebuild -project HiddenAdventures.xcodeproj -scheme HiddenAdventures -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HiddenAdventuresTests/AdventureSharePayloadTests test
```

Expected: PASS.

Commit:

```bash
git add App/Features/Sharing/AdventureSharePayload.swift App/Features/Sharing/InviteFriendsModels.swift App/Features/Sharing/InviteFriendsService.swift App/Services/MockFixtures.swift App/HiddenAdventuresApp.swift Tests/AdventureSharePayloadTests.swift
git commit -m "feat: add sharing payload and invite service seams"
```

### Task 2: Build The Invite Friends Screen Model

**Files:**
- Create: `App/Features/Sharing/InviteFriendsScreenModel.swift`
- Create: `Tests/InviteFriendsScreenModelTests.swift`

- [ ] **Step 1: Write the failing screen-model tests**

```swift
import XCTest
@testable import HiddenAdventures

final class InviteFriendsScreenModelTests: XCTestCase {
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
  }

  func testSelectionControlsInviteButtonState() {
    let model = InviteFriendsScreenModel(permissionState: .authorized, contacts: MockFixtures.inviteContacts)
    XCTAssertFalse(model.canSendInvites)
    model.toggleSelection(contactID: MockFixtures.inviteContacts[0].id)
    XCTAssertTrue(model.canSendInvites)
  }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
xcodebuild -project HiddenAdventures.xcodeproj -scheme HiddenAdventures -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HiddenAdventuresTests/InviteFriendsScreenModelTests test
```

Expected: FAIL because `InviteFriendsScreenModel` does not exist.

- [ ] **Step 3: Implement the minimal screen model**

```swift
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
    permissionState == .authorized && selectedContactIDs.isEmpty == false
  }

  func toggleSelection(contactID: String) {
    if selectedContactIDs.contains(contactID) {
      selectedContactIDs.remove(contactID)
    } else {
      selectedContactIDs.insert(contactID)
    }
  }
}
```

- [ ] **Step 4: Add composer-result and fallback coverage**

```swift
enum InviteComposerResult: Equatable {
  case sent(Int)
  case cancelled
  case failed
}

extension InviteFriendsScreenModel {
  var selectedContacts: [InviteFriendContact] {
    contacts.filter { selectedContactIDs.contains($0.id) }
  }

  var fallbackMessage: String {
    "Share Hidden Adventures with friends even if Contacts access is unavailable."
  }
}
```

- [ ] **Step 5: Run the focused tests and commit**

Run:

```bash
xcodebuild -project HiddenAdventures.xcodeproj -scheme HiddenAdventures -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HiddenAdventuresTests/InviteFriendsScreenModelTests test
```

Expected: PASS.

Commit:

```bash
git add App/Features/Sharing/InviteFriendsScreenModel.swift Tests/InviteFriendsScreenModelTests.swift
git commit -m "feat: add invite friends state model"
```

### Task 3: Add Invite Friends Navigation And The SwiftUI Flow

**Files:**
- Modify: `App/AppCoordinator.swift`
- Modify: `App/RootView.swift`
- Modify: `App/Features/Profile/ProfileView.swift`
- Create: `App/Features/Sharing/InviteFriendsView.swift`
- Create: `App/Features/Sharing/InviteFriendsMessageComposer.swift`
- Modify: `project.yml`
- Test: `UITests/Screens/ProfileScreenUITests.swift`

- [ ] **Step 1: Write the failing UI test for the profile entrypoint**

```swift
func testProfile_opensInviteFriendsFlow() throws {
  let app = launchApp(startScreen: "explore-profile")

  app.buttons["profile.inviteFriends"].tap()

  XCTAssertTrue(app.staticTexts["inviteFriends.title"].waitForExistence(timeout: 2))
  XCTAssertTrue(app.buttons["inviteFriends.cta"].exists)
}
```

- [ ] **Step 2: Run the UI test to verify it fails**

Run:

```bash
xcodebuild -project HiddenAdventures.xcodeproj -scheme HiddenAdventures -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HiddenAdventuresUITests/ProfileScreenUITests/testProfile_opensInviteFriendsFlow test
```

Expected: FAIL because the entrypoint and route do not exist yet.

- [ ] **Step 3: Add the route and profile entrypoint**

```swift
enum AppRoute: Hashable {
  case detail(String)
  case profile(String)
  case inviteFriends
}
```

```swift
Button {
  onOpenInviteFriends()
} label: {
  Label("Invite Friends", systemImage: "person.crop.circle.badge.plus")
    .font(.system(size: 16, weight: .semibold))
    .frame(maxWidth: .infinity)
    .padding(.vertical, 14)
}
.buttonStyle(.plain)
.background(HATheme.Colors.card)
.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
.overlay {
  RoundedRectangle(cornerRadius: 18, style: .continuous)
    .stroke(HATheme.Colors.border, lineWidth: 1)
}
.accessibilityIdentifier("profile.inviteFriends")
```

- [ ] **Step 4: Build the view shell and permission explainer**

```swift
import SwiftUI

struct InviteFriendsView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var model: InviteFriendsScreenModel
  let service: InviteFriendsService

  var body: some View {
    Group {
      switch model.permissionState {
      case .notDetermined:
        permissionIntro
      case .authorized:
        contactPicker
      case .denied, .restricted:
        fallbackState
      }
    }
    .navigationBarBackButtonHidden(true)
    .toolbar(.hidden, for: .navigationBar)
  }
}
```

```swift
settings:
  base:
    INFOPLIST_KEY_NSContactsUsageDescription: Hidden Adventures uses Contacts only to help you choose friends to invite by text.
```

- [ ] **Step 5: Run the UI test and commit**

Run:

```bash
xcodebuild -project HiddenAdventures.xcodeproj -scheme HiddenAdventures -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HiddenAdventuresUITests/ProfileScreenUITests/testProfile_opensInviteFriendsFlow test
```

Expected: PASS.

Commit:

```bash
git add App/AppCoordinator.swift App/RootView.swift App/Features/Profile/ProfileView.swift App/Features/Sharing/InviteFriendsView.swift App/Features/Sharing/InviteFriendsMessageComposer.swift project.yml UITests/Screens/ProfileScreenUITests.swift
git commit -m "feat: add invite friends navigation flow"
```

### Task 4: Finish Invite Contacts, Search, Selection, And Fallback States

**Files:**
- Modify: `App/Features/Sharing/InviteFriendsView.swift`
- Modify: `App/Features/Sharing/InviteFriendsService.swift`
- Modify: `App/Services/MockFixtures.swift`
- Modify: `UITests/Screens/ProfileScreenUITests.swift`

- [ ] **Step 1: Write the failing UI tests for authorized and denied states**

```swift
func testInviteFriends_authorizedStateSupportsSearchAndSelection() throws {
  let app = launchApp(
    startScreen: "explore-profile",
    extraEnv: ["UITEST_INVITE_PERMISSION": "authorized"]
  )

  app.buttons["profile.inviteFriends"].tap()
  app.textFields["inviteFriends.search"].tap()
  app.textFields["inviteFriends.search"].typeText("Sarah")
  app.buttons["inviteFriends.contact.\(MockFixtures.inviteContacts[0].id)"].tap()

  XCTAssertTrue(app.buttons["inviteFriends.cta"].isEnabled)
}

func testInviteFriends_deniedStateShowsFallback() throws {
  let app = launchApp(
    startScreen: "explore-profile",
    extraEnv: ["UITEST_INVITE_PERMISSION": "denied"]
  )

  app.buttons["profile.inviteFriends"].tap()
  XCTAssertTrue(app.staticTexts["inviteFriends.fallbackMessage"].waitForExistence(timeout: 2))
}
```

- [ ] **Step 2: Run the UI tests to verify they fail**

Run:

```bash
xcodebuild -project HiddenAdventures.xcodeproj -scheme HiddenAdventures -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HiddenAdventuresUITests/ProfileScreenUITests/testInviteFriends_authorizedStateSupportsSearchAndSelection -only-testing:HiddenAdventuresUITests/ProfileScreenUITests/testInviteFriends_deniedStateShowsFallback test
```

Expected: FAIL because fixture invite permission switching and the picker UI are incomplete.

- [ ] **Step 3: Add environment-driven fixture permission states**

```swift
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
  func requestAccess() async -> InviteFriendsPermissionState { permission == .notDetermined ? .authorized : permission }
  func loadContacts() async throws -> [InviteFriendContact] { MockFixtures.inviteContacts }
  func canSendTextMessages() -> Bool { true }
}
```

- [ ] **Step 4: Implement the searchable picker and denied fallback**

```swift
private var contactPicker: some View {
  VStack(spacing: 16) {
    TextField("Search contacts", text: $model.searchText)
      .accessibilityIdentifier("inviteFriends.search")

    ScrollView {
      LazyVStack(spacing: 12) {
        ForEach(model.visibleContacts) { contact in
          Button {
            model.toggleSelection(contactID: contact.id)
          } label: {
            HStack {
              VStack(alignment: .leading, spacing: 4) {
                Text(contact.displayName)
                Text(contact.phoneNumber)
              }
              Spacer()
              Image(systemName: model.selectedContactIDs.contains(contact.id) ? "checkmark.circle.fill" : "circle")
            }
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("inviteFriends.contact.\(contact.id)")
        }
      }
    }

    Button("Invite via Messages") { presentComposer = true }
      .disabled(model.canSendInvites == false)
      .accessibilityIdentifier("inviteFriends.cta")
  }
}
```

```swift
private var fallbackState: some View {
  VStack(spacing: 12) {
    Text("Contacts access is off.")
    Text(model.fallbackMessage)
      .accessibilityIdentifier("inviteFriends.fallbackMessage")
    Button("Share App Invite") { presentFallbackShare = true }
  }
}
```

- [ ] **Step 5: Run the UI tests and commit**

Run:

```bash
xcodebuild -project HiddenAdventures.xcodeproj -scheme HiddenAdventures -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HiddenAdventuresUITests/ProfileScreenUITests/testInviteFriends_authorizedStateSupportsSearchAndSelection -only-testing:HiddenAdventuresUITests/ProfileScreenUITests/testInviteFriends_deniedStateShowsFallback test
```

Expected: PASS.

Commit:

```bash
git add App/Features/Sharing/InviteFriendsView.swift App/Features/Sharing/InviteFriendsService.swift App/Services/MockFixtures.swift UITests/Screens/ProfileScreenUITests.swift
git commit -m "feat: add invite contact selection and fallback states"
```

### Task 5: Wire The SMS Composer And Completion States

**Files:**
- Modify: `App/Features/Sharing/InviteFriendsView.swift`
- Modify: `App/Features/Sharing/InviteFriendsMessageComposer.swift`
- Modify: `App/Features/Sharing/InviteFriendsScreenModel.swift`
- Modify: `UITests/Screens/ProfileScreenUITests.swift`

- [ ] **Step 1: Write the failing UI test for invite completion**

```swift
func testInviteFriends_sentStateShowsCompletionCopy() throws {
  let app = launchApp(
    startScreen: "explore-profile",
    extraEnv: [
      "UITEST_INVITE_PERMISSION": "authorized",
      "UITEST_INVITE_COMPOSER_RESULT": "sent"
    ]
  )

  app.buttons["profile.inviteFriends"].tap()
  app.buttons["inviteFriends.contact.\(MockFixtures.inviteContacts[0].id)"].tap()
  app.buttons["inviteFriends.cta"].tap()

  XCTAssertTrue(app.staticTexts["inviteFriends.completion"].waitForExistence(timeout: 2))
}
```

- [ ] **Step 2: Run the UI test to verify it fails**

Run:

```bash
xcodebuild -project HiddenAdventures.xcodeproj -scheme HiddenAdventures -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HiddenAdventuresUITests/ProfileScreenUITests/testInviteFriends_sentStateShowsCompletionCopy test
```

Expected: FAIL because the composer bridge is not updating completion state yet.

- [ ] **Step 3: Implement the message composer bridge**

```swift
import MessageUI
import SwiftUI

struct InviteFriendsMessageComposer: UIViewControllerRepresentable {
  let recipients: [String]
  let body: String
  let onResult: (InviteComposerResult) -> Void

  func makeUIViewController(context: Context) -> MFMessageComposeViewController {
    let controller = MFMessageComposeViewController()
    controller.messageComposeDelegate = context.coordinator
    controller.recipients = recipients
    controller.body = body
    return controller
  }
}
```

- [ ] **Step 4: Translate composer results into a lightweight completion state**

```swift
extension InviteFriendsScreenModel {
  func handleComposerResult(_ result: MessageComposeResult) {
    switch result {
    case .sent:
      completionState = .sent(selectedContactIDs.count)
      selectedContactIDs.removeAll()
    case .cancelled:
      completionState = .cancelled
    case .failed:
      completionState = .failed
    @unknown default:
      completionState = .failed
    }
  }
}
```

```swift
if let completionState = model.completionState {
  Text(completionState.title)
    .accessibilityIdentifier("inviteFriends.completion")
}
```

- [ ] **Step 5: Run the UI test and commit**

Run:

```bash
xcodebuild -project HiddenAdventures.xcodeproj -scheme HiddenAdventures -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HiddenAdventuresUITests/ProfileScreenUITests/testInviteFriends_sentStateShowsCompletionCopy test
```

Expected: PASS.

Commit:

```bash
git add App/Features/Sharing/InviteFriendsView.swift App/Features/Sharing/InviteFriendsMessageComposer.swift App/Features/Sharing/InviteFriendsScreenModel.swift UITests/Screens/ProfileScreenUITests.swift
git commit -m "feat: add invite composer completion states"
```

### Task 6: Replace The Placeholder Detail Share Action

**Files:**
- Modify: `App/Features/AdventureDetail/AdventureDetailView.swift`
- Create: `App/Features/Sharing/AdventureShareSheet.swift`
- Modify: `UITests/Screens/DetailScreenUITests.swift`
- Test: `Tests/AdventureSharePayloadTests.swift`

- [ ] **Step 1: Extend tests to cover public and non-public share behavior**

```swift
func testDetail_publicAdventureKeepsShareEnabled() throws {
  let app = launchApp(
    startScreen: "detail",
    extraEnv: ["UITEST_DETAIL_ID": eagleID]
  )

  XCTAssertTrue(app.buttons["detail.share"].isEnabled)
}

func testDetail_nonPublicAdventureShowsShareExplanation() throws {
  let app = launchApp(
    startScreen: "detail",
    extraEnv: ["UITEST_DETAIL_ID": bluePoolID]
  )

  app.buttons["detail.share"].tap()
  XCTAssertTrue(app.staticTexts["detail.shareUnavailableMessage"].waitForExistence(timeout: 2))
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run:

```bash
xcodebuild -project HiddenAdventures.xcodeproj -scheme HiddenAdventures -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HiddenAdventuresUITests/DetailScreenUITests/testDetail_publicAdventureKeepsShareEnabled -only-testing:HiddenAdventuresUITests/DetailScreenUITests/testDetail_nonPublicAdventureShowsShareExplanation test
```

Expected: FAIL because the current button is placeholder behavior and disabled rules are wrong.

- [ ] **Step 3: Present a real share sheet for public adventures**

```swift
@State private var sharePayload: AdventureSharePayload?
@State private var shareUnavailableMessage: String?

Button(action: handleShareTapped) {
  NavigationCircleButton(systemImage: "square.and.arrow.up")
}
.buttonStyle(.plain)
.accessibilityIdentifier("detail.share")
.sheet(item: $sharePayload) { payload in
  AdventureShareSheet(items: [payload.message, payload.url])
}
```

```swift
private func handleShareTapped() {
  guard let detail = currentAdventureDetail else { return }
  if let payload = AdventureSharePayload.make(
    detail: detail,
    baseURL: URL(string: "https://hiddenadventures.app")!
  ) {
    sharePayload = payload
  } else {
    shareUnavailableMessage = AdventureSharePayload.unavailableMessage(for: detail.visibility)
  }
}
```

- [ ] **Step 4: Add the unavailable explanatory state**

```swift
.alert(
  "Sharing unavailable",
  isPresented: Binding(
    get: { shareUnavailableMessage != nil },
    set: { if $0 == false { shareUnavailableMessage = nil } }
  )
) {
  Button("OK", role: .cancel) {}
} message: {
  Text(shareUnavailableMessage ?? "")
    .accessibilityIdentifier("detail.shareUnavailableMessage")
}
```

- [ ] **Step 5: Run the share tests and commit**

Run:

```bash
xcodebuild -project HiddenAdventures.xcodeproj -scheme HiddenAdventures -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HiddenAdventuresTests/AdventureSharePayloadTests -only-testing:HiddenAdventuresUITests/DetailScreenUITests/testDetail_publicAdventureKeepsShareEnabled -only-testing:HiddenAdventuresUITests/DetailScreenUITests/testDetail_nonPublicAdventureShowsShareExplanation test
```

Expected: PASS.

Commit:

```bash
git add App/Features/AdventureDetail/AdventureDetailView.swift App/Features/Sharing/AdventureShareSheet.swift UITests/Screens/DetailScreenUITests.swift Tests/AdventureSharePayloadTests.swift
git commit -m "feat: add public adventure share flow"
```

### Task 7: Verify The Full Mock-First Slice And Record Handoff Notes

**Files:**
- Modify: `UITests/Screens/ProfileScreenUITests.swift`
- Modify: `UITests/Screens/DetailScreenUITests.swift`
- Modify: `Docs/manual-qa-results.md`

- [ ] **Step 1: Add a compact regression pass for the feature happy paths**

```swift
func testInviteFriends_andShareAdventure_smoke() throws {
  let profileApp = launchApp(
    startScreen: "explore-profile",
    extraEnv: ["UITEST_INVITE_PERMISSION": "authorized"]
  )
  profileApp.buttons["profile.inviteFriends"].tap()
  XCTAssertTrue(profileApp.buttons["inviteFriends.cta"].exists)

  let detailApp = launchApp(
    startScreen: "detail",
    extraEnv: ["UITEST_DETAIL_ID": eagleID]
  )
  XCTAssertTrue(detailApp.buttons["detail.share"].exists)
}
```

- [ ] **Step 2: Run focused unit tests**

Run:

```bash
xcodebuild -project HiddenAdventures.xcodeproj -scheme HiddenAdventures -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HiddenAdventuresTests/AdventureSharePayloadTests -only-testing:HiddenAdventuresTests/InviteFriendsScreenModelTests test
```

Expected: PASS.

- [ ] **Step 3: Run focused UI tests**

Run:

```bash
xcodebuild -project HiddenAdventures.xcodeproj -scheme HiddenAdventures -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HiddenAdventuresUITests/ProfileScreenUITests -only-testing:HiddenAdventuresUITests/DetailScreenUITests test
```

Expected: PASS for the newly added invite/share coverage plus no regressions in existing profile/detail smoke cases.

- [ ] **Step 4: Record manual QA and integration blockers**

```md
Feature: Adventure Sharing + Friend Invites
Environment: Local fixture preview and LocalManualQA
Validated: Invite entrypoint, permission explainer, authorized picker, denied fallback, SMS composer handoff, public share button, non-public share explanation
Blocked integrated behavior: canonical HTTPS host and associated-domain contract for universal-link open/install fallback
```

- [ ] **Step 5: Commit**

```bash
git add UITests/Screens/ProfileScreenUITests.swift UITests/Screens/DetailScreenUITests.swift Docs/manual-qa-results.md
git commit -m "test: cover adventure sharing and invite flows"
```

## Cross-Repo Handoff After This Plan

Other repos can rely on these outcomes once this plan is implemented:

- `hidden-adventures-plan`
  iOS mock-first scope is explicitly separated from the later universal-link integration dependency.
- `hidden-adventures-server`
  The app-side share URL shape and invite-copy needs are clear, but no invite backend or referral contract is required for v1 mock acceptance.
- `v0-hidden-adventures-ui`
  Profile needs a dedicated `Invite Friends` entry and Adventure Detail needs a public-only share affordance with explanatory unavailable state for non-public adventures.

## Missing Decision That Prevents Full Integrated Completion

The safe blocker is the canonical public link strategy. Before claiming `Integrated iOS accepted`, the program must decide the exact public host and universal-link ownership model for shared adventure URLs.
