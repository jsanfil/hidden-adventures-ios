import SwiftUI

struct ProfileSetupView: View {
  let initialDraft: ProfileBootstrapDraft
  let showsSkip: Bool
  let onBack: () -> Void
  let onSkip: () -> Void
  let onContinue: (ProfileBootstrapDraft) -> Void

  @State private var draft: ProfileBootstrapDraft

  init(
    initialDraft: ProfileBootstrapDraft,
    showsSkip: Bool,
    onBack: @escaping () -> Void,
    onSkip: @escaping () -> Void,
    onContinue: @escaping (ProfileBootstrapDraft) -> Void
  ) {
    self.initialDraft = initialDraft
    self.showsSkip = showsSkip
    self.onBack = onBack
    self.onSkip = onSkip
    self.onContinue = onContinue
    _draft = State(initialValue: initialDraft)
  }

  var body: some View {
    ZStack {
      HATheme.Colors.background
        .ignoresSafeArea()

      VStack(spacing: 0) {
        HAStatusBarSpacer()

        HStack {
          Button(action: onBack) {
            Image(systemName: "chevron.left")
              .font(.system(size: 22, weight: .medium))
              .foregroundStyle(HATheme.Colors.foreground)
              .frame(width: 40, height: 40)
              .offset(x: -2)
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("profile.back")

          Spacer()

          if showsSkip {
            Button("Skip", action: onSkip)
              .font(HATheme.Typography.body)
              .foregroundStyle(HATheme.Colors.mutedForeground)
              .buttonStyle(.plain)
              .accessibilityIdentifier("profile.skip")
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)

        VStack(alignment: .leading, spacing: 28) {
          VStack(alignment: .leading, spacing: 8) {
            Text("Set up your profile")
              .font(HATheme.Typography.screenTitle)
              .foregroundStyle(HATheme.Colors.foreground)

            Text("Choose your public handle, then share the basics other explorers should see.")
              .font(HATheme.Typography.body)
              .foregroundStyle(HATheme.Colors.mutedForeground)
          }

          VStack(spacing: 24) {
            ZStack(alignment: .bottomTrailing) {
              HAAvatarView(
                initials: draft.initials,
                size: 112,
                background: HATheme.Colors.secondary,
                foreground: HATheme.Colors.mutedForeground
              )

              Circle()
                .fill(HATheme.Colors.primary)
                .frame(width: 34, height: 34)
                .overlay {
                  Image(systemName: "camera.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                }
                .opacity(0.45)
                .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 18) {
              field(title: "Display name") {
                TextField("How should we call you?", text: $draft.displayName)
                  .font(HATheme.Typography.body)
                  .foregroundStyle(HATheme.Colors.foreground)
                  .haFieldStyle()
                  .accessibilityIdentifier("profile.displayName")
              }

              field(title: "Handle") {
                HStack(spacing: 12) {
                  Text("@")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(HATheme.Colors.mutedForeground)

                  TextField("public_handle", text: $draft.handle)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .font(HATheme.Typography.body)
                    .foregroundStyle(HATheme.Colors.foreground)
                    .accessibilityIdentifier("profile.handle")
                }
                .haFieldStyle()
              }

              HStack(alignment: .top, spacing: 12) {
                field(title: "City") {
                  TextField("Portland", text: $draft.homeCity)
                    .font(HATheme.Typography.body)
                    .foregroundStyle(HATheme.Colors.foreground)
                    .haFieldStyle()
                    .accessibilityIdentifier("profile.homeCity")
                }

                field(title: "State") {
                  TextField("OR", text: $draft.homeRegion)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled(true)
                    .font(HATheme.Typography.body)
                    .foregroundStyle(HATheme.Colors.foreground)
                    .haFieldStyle()
                    .accessibilityIdentifier("profile.homeRegion")
                }
              }

              field(title: "Bio", secondaryTitle: "(optional)") {
                TextField("What kind of adventures do you love?", text: $draft.bio, axis: .vertical)
                  .font(HATheme.Typography.body)
                  .foregroundStyle(HATheme.Colors.foreground)
                  .lineLimit(4, reservesSpace: true)
                  .padding(16)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .background(HATheme.Colors.secondary)
                  .clipShape(RoundedRectangle(cornerRadius: HATheme.Radius.input, style: .continuous))
                  .accessibilityIdentifier("profile.bio")
              }
            }
          }

          Spacer()

          HAPrimaryButton(title: "Continue") {
            onContinue(normalizedDraft)
          }
          .accessibilityIdentifier("profile.continue")
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 32)
      }
    }
    .toolbar(.hidden, for: .navigationBar)
  }

  private var normalizedDraft: ProfileBootstrapDraft {
    ProfileBootstrapDraft(
      displayName: draft.displayName.trimmingCharacters(in: .whitespacesAndNewlines),
      handle: draft.handle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
      homeCity: draft.homeCity.trimmingCharacters(in: .whitespacesAndNewlines),
      homeRegion: draft.homeRegion.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
      bio: draft.bio.trimmingCharacters(in: .whitespacesAndNewlines),
      initials: draft.initials
    )
  }

  @ViewBuilder
  private func field<Content: View>(
    title: String,
    secondaryTitle: String? = nil,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 4) {
        Text(title)
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(HATheme.Colors.foreground)

        if let secondaryTitle {
          Text(secondaryTitle)
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(HATheme.Colors.mutedForeground)
        }
      }

      content()
    }
  }
}

struct ProfileSetupView_Previews: PreviewProvider {
  static var previews: some View {
    ProfileSetupView(
      initialDraft: MockFixtures.bootstrapDraft,
      showsSkip: true,
      onBack: {},
      onSkip: {},
      onContinue: { _ in }
    )
  }
}
