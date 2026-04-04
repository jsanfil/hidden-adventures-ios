import SwiftUI

struct EmailAuthView: View {
  let intent: WelcomeIntent
  let onBack: () -> Void
  let onContinue: (String) -> Void

  @State private var email = ""

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
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("auth.email.back")

          Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)

        VStack(alignment: .leading, spacing: 28) {
          VStack(alignment: .leading, spacing: 8) {
            Text(intent == .onboarding ? "Start with your email" : "Sign in with your email")
              .font(HATheme.Typography.screenTitle)
              .foregroundStyle(HATheme.Colors.foreground)

            Text(intent == .onboarding
              ? "We’ll send a one-time code so you can create or continue your Hidden Adventures account."
              : "We’ll send a one-time code to verify it’s really you."
            )
            .font(HATheme.Typography.body)
            .foregroundStyle(HATheme.Colors.mutedForeground)
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("Email")
              .font(.system(size: 14, weight: .medium))
              .foregroundStyle(HATheme.Colors.foreground)

            TextField("you@example.com", text: $email)
              .keyboardType(.emailAddress)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled(true)
              .font(HATheme.Typography.body)
              .foregroundStyle(HATheme.Colors.foreground)
              .haFieldStyle()
              .accessibilityIdentifier("auth.email.field")
          }

          Spacer()

          HAPrimaryButton(title: "Continue") {
            onContinue(email)
          }
          .accessibilityIdentifier("auth.email.continue")
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 32)
      }
    }
    .toolbar(.hidden, for: .navigationBar)
  }
}

struct EmailAuthView_Previews: PreviewProvider {
  static var previews: some View {
    EmailAuthView(
      intent: .onboarding,
      onBack: {},
      onContinue: { _ in }
    )
  }
}
