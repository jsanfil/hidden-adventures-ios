import SwiftUI

struct InviteFriendsView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var model: InviteFriendsScreenModel

  let service: InviteFriendsService

  @State private var hasLoaded = false

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
      HAPrimaryButton(title: "Invite by text") {}
        .accessibilityIdentifier("inviteFriends.cta")
    }
  }

  private var fallbackState: some View {
    contentCard(
      eyebrow: "Invite your people",
      title: "Share Hidden Adventures",
      message: model.fallbackMessage
    ) {
      HAPrimaryButton(title: "Share invite link") {}
        .accessibilityIdentifier("inviteFriends.cta")
    }
  }

  private var authorizedMessage: String {
    let count = model.contacts.count

    if count == 0 {
      return "Contacts access is ready. We’ll show your invite list here as the full picker lands."
    }

    return "Contacts access is ready with \(count) friends available in this fixture shell."
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

      Spacer(minLength: 0)

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

      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .padding(24)
    .background(HATheme.Colors.card)
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .stroke(HATheme.Colors.border, lineWidth: 1)
    }
  }

  @MainActor
  private func loadPermissionState() async {
    let permissionState = await service.permissionState()
    model.permissionState = permissionState

    guard permissionState == .authorized else { return }
    model.contacts = (try? await service.loadContacts()) ?? []
  }

  @MainActor
  private func requestAccess() async {
    let permissionState = await service.requestAccess()
    model.permissionState = permissionState

    guard permissionState == .authorized else { return }
    model.contacts = (try? await service.loadContacts()) ?? []
  }
}

struct InviteFriendsView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      InviteFriendsView(service: FixtureInviteFriendsService())
    }
  }
}
