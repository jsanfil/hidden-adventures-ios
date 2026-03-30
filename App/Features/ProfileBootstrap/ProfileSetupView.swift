import SwiftUI

struct ProfileSetupView: View {
  let initialDraft: ProfileBootstrapDraft
  let showsSkip: Bool
  let usesHandleOnlyContract: Bool
  let onBack: () -> Void
  let onSkip: () -> Void
  let onContinue: (ProfileBootstrapDraft) -> Void

  @State private var draft: ProfileBootstrapDraft

  init(
    initialDraft: ProfileBootstrapDraft,
    showsSkip: Bool,
    usesHandleOnlyContract: Bool,
    onBack: @escaping () -> Void,
    onSkip: @escaping () -> Void,
    onContinue: @escaping (ProfileBootstrapDraft) -> Void
  ) {
    self.initialDraft = initialDraft
    self.showsSkip = showsSkip
    self.usesHandleOnlyContract = usesHandleOnlyContract
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

            Text("Let other explorers know who you are")
              .font(HATheme.Typography.body)
              .foregroundStyle(HATheme.Colors.mutedForeground)
          }

          if usesHandleOnlyContract {
            Text("Slice 1 live setup only reserves your public handle. Display name, home base, and bio stay local until a profile-write contract lands.")
              .font(.system(size: 13, weight: .medium))
              .foregroundStyle(HATheme.Colors.mutedForeground)
              .padding(14)
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(HATheme.Colors.secondary)
              .clipShape(RoundedRectangle(cornerRadius: HATheme.Radius.card, style: .continuous))
              .accessibilityIdentifier("profile.handleOnlyNote")
          }

          VStack(spacing: 24) {
            ZStack(alignment: .bottomTrailing) {
              HAAvatarView(
                initials: draft.initials,
                size: 112,
                background: HATheme.Colors.secondary,
                foreground: HATheme.Colors.mutedForeground
              )

              Button(action: {}) {
                Image(systemName: "camera.fill")
                  .font(.system(size: 14, weight: .semibold))
                  .foregroundStyle(.white)
                  .frame(width: 34, height: 34)
                  .background(HATheme.Colors.primary)
                  .clipShape(Circle())
                  .shadow(color: HATheme.Colors.shadow, radius: 6, x: 0, y: 3)
              }
              .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 18) {
              field(title: "Display name") {
                TextField("How should we call you?", text: $draft.displayName)
                  .font(HATheme.Typography.body)
                  .foregroundStyle(HATheme.Colors.foreground)
                  .haFieldStyle()
                  .disabled(usesHandleOnlyContract)
                  .accessibilityIdentifier("profile.displayName")
              }

              field(title: "Home base") {
                HStack(spacing: 12) {
                  Image(systemName: "mappin")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(HATheme.Colors.mutedForeground)

                  TextField("City or region", text: $draft.homeBase)
                    .font(HATheme.Typography.body)
                    .foregroundStyle(HATheme.Colors.foreground)
                    .disabled(usesHandleOnlyContract)
                    .accessibilityIdentifier("profile.homeBase")
                }
                .haFieldStyle()
              }

              field(title: "Bio", secondaryTitle: "(optional)") {
                TextField("What kind of adventures do you love?", text: $draft.bio, axis: .vertical)
                  .font(HATheme.Typography.body)
                  .foregroundStyle(HATheme.Colors.foreground)
                  .lineLimit(4, reservesSpace: true)
                  .padding(16)
                  .disabled(usesHandleOnlyContract)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .background(HATheme.Colors.secondary)
                  .clipShape(RoundedRectangle(cornerRadius: HATheme.Radius.input, style: .continuous))
                  .accessibilityIdentifier("profile.bio")
              }
            }
          }

          Spacer()

          HAPrimaryButton(title: "Continue") {
            onContinue(draft)
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
