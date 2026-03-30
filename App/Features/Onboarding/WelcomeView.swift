import SwiftUI

struct WelcomeView: View {
  let onGetStarted: () -> Void
  let onSignIn: () -> Void
  private let contentWidth: CGFloat = 320
  private let bodyWidth: CGFloat = 286

  var body: some View {
    ZStack {
      Image("hero-mountain")
        .resizable()
        .scaledToFill()
        .ignoresSafeArea()

      LinearGradient(
        colors: [
          .black.opacity(0.22),
          .black.opacity(0.10),
          .black.opacity(0.72)
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      VStack {
        VStack(spacing: 0) {
          ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .fill(.white.opacity(0.95))
              .frame(width: 64, height: 64)
              .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)

            Image(systemName: "safari")
              .font(.system(size: 34, weight: .regular))
              .foregroundStyle(HATheme.Colors.primary)
          }
          .padding(.bottom, 16)

          Text("Hidden Adventures")
            .font(.system(size: 30, weight: .regular, design: .serif))
            .tracking(-0.8)
            .foregroundStyle(.white)
            .accessibilityIdentifier("welcome.brandTitle")
        }
        .padding(.top, 32)

        Spacer()

        VStack(spacing: 24) {
          VStack(spacing: 8) {
            Text("Discover the extraordinary")
              .font(.system(size: 24, weight: .medium))
              .multilineTextAlignment(.center)
              .foregroundStyle(.white)
              .fixedSize(horizontal: false, vertical: true)
              .frame(maxWidth: bodyWidth)
              .accessibilityIdentifier("welcome.headline")

            Text("Find hidden gems, scenic trails, and unforgettable places shared by explorers like you.")
              .font(HATheme.Typography.body)
              .foregroundStyle(.white.opacity(0.82))
              .multilineTextAlignment(.center)
              .lineSpacing(3)
              .fixedSize(horizontal: false, vertical: true)
              .frame(maxWidth: bodyWidth)
              .accessibilityIdentifier("welcome.subheadline")
          }
          .frame(maxWidth: contentWidth)

          VStack(spacing: 12) {
            Button(action: onGetStarted) {
              Text("Get Started")
                .font(HATheme.Typography.bodyMedium)
                .foregroundStyle(HATheme.Colors.foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("welcome.getStarted")
            .frame(maxWidth: contentWidth)

            Button(action: onSignIn) {
              Text("Already have an account? ")
                .foregroundStyle(.white.opacity(0.72))
              +
              Text("Sign In")
                .foregroundStyle(.white)
                .underline()
            }
            .font(.system(size: 14, weight: .semibold))
            .buttonStyle(.plain)
            .accessibilityIdentifier("welcome.signIn")
          }
          .frame(maxWidth: contentWidth)

          Text("By continuing, you agree to our Terms of Service and Privacy Policy")
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(.white.opacity(0.6))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 260)
            .accessibilityIdentifier("welcome.legal")
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.bottom, 48)
      }
      .padding(.top, 64)
    }
    .toolbar(.hidden, for: .navigationBar)
  }
}
