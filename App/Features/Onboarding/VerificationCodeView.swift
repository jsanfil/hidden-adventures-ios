import SwiftUI

struct VerificationCodeView: View {
  let challenge: PendingAuthChallenge?
  let onBack: () -> Void
  let onResend: () -> Void
  let onContinue: (String) -> Void

  @State private var code = ""

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
          .accessibilityIdentifier("auth.code.back")

          Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)

        VStack(alignment: .leading, spacing: 28) {
          VStack(alignment: .leading, spacing: 8) {
            Text("Enter your code")
              .font(HATheme.Typography.screenTitle)
              .foregroundStyle(HATheme.Colors.foreground)

            Text(helperText)
              .font(HATheme.Typography.body)
              .foregroundStyle(HATheme.Colors.mutedForeground)
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("Verification code")
              .font(.system(size: 14, weight: .medium))
              .foregroundStyle(HATheme.Colors.foreground)

            TextField("123456", text: $code)
              .keyboardType(.numberPad)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled(true)
              .font(.system(size: 28, weight: .semibold, design: .monospaced))
              .foregroundStyle(HATheme.Colors.foreground)
              .haFieldStyle()
              .accessibilityIdentifier("auth.code.field")
          }

          Spacer()

          Button("Send a new code", action: onResend)
            .buttonStyle(.plain)
            .font(HATheme.Typography.body)
            .foregroundStyle(HATheme.Colors.primary)
            .accessibilityIdentifier("auth.code.resend")

          HAPrimaryButton(title: "Verify") {
            onContinue(code)
          }
          .accessibilityIdentifier("auth.code.continue")
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 32)
      }
    }
    .toolbar(.hidden, for: .navigationBar)
  }

  private var helperText: String {
    guard let challenge else {
      return "We sent a one-time code to your email."
    }

    return challenge.codeEntryHelperText
  }
}

struct VerificationCodeView_Previews: PreviewProvider {
  static var previews: some View {
    VerificationCodeView(
      challenge: PendingAuthChallenge(
        kind: .signIn,
        cognitoUsername: "test@example.com",
        email: "test@example.com",
        deliveryDestination: "t•••@example.com",
        session: "session"
      ),
      onBack: {},
      onResend: {},
      onContinue: { _ in }
    )
  }
}
