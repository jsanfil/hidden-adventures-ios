import SwiftUI
import UIKit

struct InviteFriendsView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var model: InviteFriendsScreenModel

  let service: InviteFriendsService

  @State private var hasLoaded = false
  @State private var presentComposer = false
  @State private var presentFallbackShare = false
  @FocusState private var isSearchFocused: Bool

  init(service: InviteFriendsService) {
    self.service = service
    _model = StateObject(wrappedValue: InviteFriendsScreenModel(permissionState: .notDetermined))
  }

  var body: some View {
    ZStack {
      HATheme.Colors.background
        .ignoresSafeArea()

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
      .padding(.horizontal, 24)
      .padding(.vertical, 18)
    }
    .task {
      guard hasLoaded == false else { return }
      hasLoaded = true
      await loadPermissionState()
    }
    .sheet(isPresented: $presentComposer) {
      InviteFriendsMessageComposer(
        recipients: model.selectedContacts.map(\.phoneNumber),
        bodyText: MockFixtures.inviteMessage,
        onResult: handleComposerResult
      )
    }
    .sheet(isPresented: $presentFallbackShare) {
      InviteFriendsShareSheet(items: [MockFixtures.inviteMessage, MockFixtures.inviteAppURL])
    }
    .navigationBarBackButtonHidden(true)
    .toolbar(.hidden, for: .navigationBar)
  }

  private var permissionIntro: some View {
    contentCard(
      eyebrow: "Invite your people",
      title: "Build your adventure crew",
      message: "We use Contacts only to help you choose who to invite by text. Nothing is uploaded."
    ) {
      HAPrimaryButton(title: "Choose friends to invite") {
        Task {
          await requestAccess()
        }
      }
      .accessibilityIdentifier("inviteFriends.cta")
    }
  }

  private var contactPicker: some View {
    contentCard(
      eyebrow: "Invite your people",
      title: "Pick friends to text",
      message: authorizedMessage
    ) {
      VStack(spacing: 16) {
        searchField

        ScrollView {
          LazyVStack(spacing: 12) {
            ForEach(model.visibleContacts) { contact in
              contactRow(for: contact)
            }
          }
        }

        if let completionState = model.completionState {
          Text(completionState.title)
            .font(HATheme.Typography.bodyMedium)
            .foregroundStyle(HATheme.Colors.primary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("inviteFriends.completion")
        }

        HAPrimaryButton(title: "Invite via Messages", action: handleInviteCTA)
        .disabled(model.canSendInvites == false || service.canSendTextMessages() == false)
        .accessibilityIdentifier("inviteFriends.cta")
      }
    }
  }

  private var fallbackState: some View {
    contentCard(
      eyebrow: "Invite your people",
      title: "Share Hidden Adventures",
      message: model.fallbackMessage
    ) {
      VStack(alignment: .leading, spacing: 12) {
        Text("Contacts access is off.")
          .font(HATheme.Typography.bodyMedium)
          .foregroundStyle(HATheme.Colors.foreground)

        Text(model.fallbackMessage)
          .font(HATheme.Typography.body)
          .foregroundStyle(HATheme.Colors.mutedForeground)
          .fixedSize(horizontal: false, vertical: true)
          .accessibilityIdentifier("inviteFriends.fallbackMessage")

        HAPrimaryButton(title: "Share App Invite") {
          presentFallbackShare = true
        }
        .accessibilityIdentifier("inviteFriends.cta")
      }
    }
  }

  private var authorizedMessage: String {
    let count = model.contacts.count

    if count == 0 {
      return "Search your contacts and choose who should get your next Hidden Adventures invite."
    }

    return "Select one or more friends below, then send your invite by text."
  }

  private var searchField: some View {
    HStack(spacing: 12) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(HATheme.Colors.mutedForeground)

      TextField("Search contacts", text: $model.searchText)
        .font(HATheme.Typography.body)
        .foregroundStyle(HATheme.Colors.foreground)
        .textInputAutocapitalization(.never)
        .disableAutocorrection(true)
        .focused($isSearchFocused)
        .accessibilityIdentifier("inviteFriends.search")
    }
    .padding(.horizontal, 18)
    .frame(height: 56)
    .background(HATheme.Colors.secondary)
    .overlay {
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .stroke(isSearchFocused ? HATheme.Colors.primary.opacity(0.45) : HATheme.Colors.secondary, lineWidth: 2)
    }
    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
  }

  private func contactRow(for contact: InviteFriendContact) -> some View {
    Button {
      model.toggleSelection(contactID: contact.id)
    } label: {
      HStack(spacing: 16) {
        VStack(alignment: .leading, spacing: 4) {
          Text(contact.displayName)
            .font(HATheme.Typography.bodyMedium)
            .foregroundStyle(HATheme.Colors.foreground)

          Text(contact.phoneNumber)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(HATheme.Colors.mutedForeground)
        }

        Spacer()

        Image(systemName: model.selectedContactIDs.contains(contact.id) ? "checkmark.circle.fill" : "circle")
          .font(.system(size: 22, weight: .semibold))
          .foregroundStyle(
            model.selectedContactIDs.contains(contact.id)
              ? HATheme.Colors.primary
              : HATheme.Colors.mutedForeground.opacity(0.85)
          )
      }
      .padding(.horizontal, 18)
      .padding(.vertical, 16)
      .background(HATheme.Colors.secondary)
      .overlay {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .stroke(
            model.selectedContactIDs.contains(contact.id)
              ? HATheme.Colors.primary.opacity(0.45)
              : HATheme.Colors.border,
            lineWidth: model.selectedContactIDs.contains(contact.id) ? 2 : 1
          )
      }
      .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("inviteFriends.contact.\(contact.id)")
  }

  private func contentCard<Footer: View>(
    eyebrow: String,
    title: String,
    message: String,
    @ViewBuilder footer: () -> Footer
  ) -> some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack {
        Button(action: { dismiss() }) {
          Image(systemName: "chevron.left")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(HATheme.Colors.foreground)
            .frame(width: 40, height: 40)
            .background(HATheme.Colors.card)
            .clipShape(Circle())
            .overlay {
              Circle()
                .stroke(HATheme.Colors.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("inviteFriends.back")

        Spacer()
      }

      VStack(alignment: .leading, spacing: 14) {
        Text(eyebrow.uppercased())
          .font(HATheme.Typography.micro)
          .tracking(1.1)
          .foregroundStyle(HATheme.Colors.primary)

        Text(title)
          .font(HATheme.Typography.screenTitle)
          .foregroundStyle(HATheme.Colors.foreground)
          .accessibilityIdentifier("inviteFriends.title")

        Text(message)
          .font(HATheme.Typography.body)
          .foregroundStyle(HATheme.Colors.mutedForeground)
          .fixedSize(horizontal: false, vertical: true)
      }

      footer()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .padding(24)
    .background(HATheme.Colors.card)
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .stroke(HATheme.Colors.border, lineWidth: 1)
    }
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("inviteFriends.shell")
  }

  @MainActor
  private func loadPermissionState() async {
    let permissionState = await service.permissionState()
    model.permissionState = permissionState

    guard permissionState == .authorized else {
      model.contacts = []
      return
    }

    model.contacts = (try? await service.loadContacts()) ?? []
  }

  @MainActor
  private func requestAccess() async {
    let permissionState = await service.requestAccess()
    model.permissionState = permissionState

    guard permissionState == .authorized else {
      model.contacts = []
      return
    }

    model.contacts = (try? await service.loadContacts()) ?? []
  }

  private func handleInviteCTA() {
    if let simulatedResult = simulatedComposerResult {
      model.handleComposerResult(simulatedResult)
      return
    }

    presentComposer = true
  }

  private func handleComposerResult(_ result: InviteComposerResult) {
    model.handleComposerResult(result)
  }

  private var simulatedComposerResult: InviteComposerResult? {
    switch ProcessInfo.processInfo.environment["UITEST_INVITE_COMPOSER_RESULT"]?.lowercased() {
    case "sent":
      return .sent(model.selectedContacts.count)
    case "cancelled":
      return .cancelled
    case "failed":
      return .failed
    default:
      return nil
    }
  }
}

private struct InviteFriendsShareSheet: UIViewControllerRepresentable {
  let items: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: items, applicationActivities: nil)
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct InviteFriendsView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      InviteFriendsView(service: FixtureInviteFriendsService())
    }
  }
}
